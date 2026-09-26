#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 MisterKnot
# SPDX-License-Identifier: GPL-3.0-or-later
"""Cinder Ash 0.01 installation, activation, backup and conservative removal."""
import argparse,hashlib,json,os,re,shutil,subprocess,sys,time,tempfile
from pathlib import Path
PACKAGE=Path(__file__).resolve().parent.parent
VERSION='0.01'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None
def run(args,required=True):
 p=subprocess.run([str(x) for x in args],text=True,capture_output=True)
 if p.returncode and required:raise RuntimeError(p.stderr.strip() or 'Command failed: '+str(args[0]))
 return p

def set_key(path,groups,key,value):
 """Edit only the requested KConfig/INI key, preserving unrelated text."""
 text=path.read_text() if path.exists() else ''
 header=''.join('['+g+']' for g in groups)
 lines=text.splitlines(keepends=True);start=None;end=len(lines)
 for i,line in enumerate(lines):
  if line.strip()==header:start=i+1;break
 if start is None:
  if text and not text.endswith('\n'):text+='\n'
  text+='\n'+header+'\n'+key+'='+value+'\n'
 else:
  for i in range(start,len(lines)):
   if re.match(r'^\[',lines[i]):end=i;break
  found=False
  for i in range(start,end):
   if re.match(r'^'+re.escape(key)+r'\s*=',lines[i]):lines[i]=key+'='+value+'\n';found=True;break
  if not found:lines.insert(end,key+'='+value+'\n')
  text=''.join(lines)
 path.parent.mkdir(parents=True,exist_ok=True)
 mode=(path.stat().st_mode & 0o777) if path.exists() else 0o600
 with tempfile.NamedTemporaryFile(mode='w',dir=path.parent,delete=False) as f:f.write(text);tmp=Path(f.name)
 tmp.chmod(mode);tmp.replace(path)

def paths(stage,system):
 if stage:
  base=stage.resolve();return (base/'usr/share',base/'etc',base/'var/lib/cinder-ash') if system else (base/'user/share',base/'user/config',base/'user/state/cinder-ash')
 if system:return Path('/usr/share'),Path('/etc'),Path('/var/lib/cinder-ash')
 return Path(os.environ.get('XDG_DATA_HOME',str(Path.home()/'.local/share'))),Path(os.environ.get('XDG_CONFIG_HOME',str(Path.home()/'.config'))),Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'cinder-ash'

def dbus_tool():
 for cmd in ['qdbus6','/usr/lib/qt6/bin/qdbus']:
  p=shutil.which(cmd)
  if p:return p
 return None

def desktop_script(code):
 tool=dbus_tool()
 if not tool:return None
 p=run([tool,'org.kde.plasmashell','/PlasmaShell','org.kde.PlasmaShell.evaluateScript',code],False)
 return p.stdout.strip() if p.returncode==0 else None

def snapshot(config_paths,state_dir):
 backups=[]
 for n,p in enumerate(config_paths):
  if p.is_symlink():raise RuntimeError('Refusing to overwrite symlink: '+str(p))
  entry={'path':str(p),'before':digest(p),'mode':(p.stat().st_mode & 0o777) if p.exists() else 0o600}
  if p.exists():
   b=state_dir/'backups'/str(n);b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b);entry['backup']=str(b)
  backups.append(entry)
 return backups

def activate_user(data,config,state,stage):
 # Copy palette groups explicitly; all icon, font and cursor groups stay untouched.
 palette=(data/'color-schemes/CinderAsh.colors').read_text()
 group=None
 for line in palette.splitlines():
  if line.startswith('['):group=line.strip('[]')
  elif '=' in line and group and (group.startswith(('Colors:','ColorEffects:')) or group=='WM'):
   key,value=line.split('=',1);set_key(config/'kdeglobals',[group],key,value)
 changes=[('kdeglobals',['KDE'],'widgetStyle','kvantum'),('kdeglobals',['General'],'ColorScheme','CinderAsh'),('kdeglobals',['General'],'LookAndFeelPackage','com.misterknot.cinderash'),('kdeglobals',['General'],'AccentColor','0,0,0,0'),('kdeglobals',['General'],'accentColorFromWallpaper','false'),('plasmarc',['Theme'],'name','CinderAsh'),('kwinrc',['org.kde.kdecoration2'],'library','org.kde.kwin.aurorae'),('kwinrc',['org.kde.kdecoration2'],'theme','__aurorae__svg__CinderAsh'),('ksplashrc',['KSplash'],'Theme','com.misterknot.cinderash'),('ksplashrc',['KSplash'],'Engine','KSplashQML'),('Kvantum/kvantum.kvconfig',['General'],'theme','CinderAsh'),('kscreenlockerrc',['Greeter'],'WallpaperPlugin','org.kde.image'),('kscreenlockerrc',['Greeter','Wallpaper','org.kde.image','General'],'Image',(data/'wallpapers/CinderAsh/contents/images/3840x2160.png').as_uri())]
 for filename,groups,key,value in changes:set_key(config/filename,groups,key,value)
 if stage:return
 wallpaper=(data/'wallpapers/CinderAsh/contents/images/3840x2160.png').as_uri()
 get='var saved=[]; var ds=desktops(); for(var i=0;i<ds.length;i++){var d=ds[i];d.currentConfigGroup=["Wallpaper",d.wallpaperPlugin,"General"];saved.push({id:d.id,plugin:d.wallpaperPlugin,image:d.readConfig("Image","")});} print(JSON.stringify(saved));'
 old=desktop_script(get)
 try:state['wallpapers']=json.loads(old) if old else []
 except (ValueError,TypeError):state['wallpapers']=[]
 if state['wallpapers']:
  state['wallpaper_applied']=wallpaper
  result=desktop_script('var ds=desktops();for(var i=0;i<ds.length;i++){var d=ds[i];d.wallpaperPlugin="org.kde.image";d.currentConfigGroup=["Wallpaper","org.kde.image","General"];d.writeConfig("Image",'+json.dumps(wallpaper)+');} print("Cinder Ash wallpaper applied");')
  if result is None:print('Wallpaper installed; select Cinder Ash in desktop Wallpaper settings.')
 else:print('Wallpaper installed; select Cinder Ash in desktop Wallpaper settings (desktop control unavailable).')
 # Make KDE broadcast its palette update, then notify existing desktop components.
 for args in [['plasma-apply-colorscheme','CinderAsh'],['plasma-apply-desktoptheme','CinderAsh'],['kvantummanager','--set','CinderAsh']]:
  if shutil.which(args[0]):run(args,False)
 tool=dbus_tool()
 if tool:run([tool,'org.kde.KWin','/KWin','reconfigure'],False)
 print('Restart open applications; log out and back in for all desktop/lock-screen changes.')

def install(stage,system):
 data,config,state_root=paths(stage,system);state_file=state_root/('sddm.json' if system else 'user.json')
 if not stage and not system and not shutil.which('kvantummanager'):raise RuntimeError('Kvantum is required. Install the Qt 6 Kvantum style and Kvantum Manager first.')
 existing=json.loads(state_file.read_text()) if state_file.exists() else None
 targets=[(PACKAGE/'sddm/CinderAsh',data/'sddm/themes/CinderAsh')] if system else [(PACKAGE/'share/color-schemes/CinderAsh.colors',data/'color-schemes/CinderAsh.colors'),(PACKAGE/'share/plasma/desktoptheme/CinderAsh',data/'plasma/desktoptheme/CinderAsh'),(PACKAGE/'share/aurorae/themes/CinderAsh',data/'aurorae/themes/CinderAsh'),(PACKAGE/'share/plasma/look-and-feel/com.misterknot.cinderash',data/'plasma/look-and-feel/com.misterknot.cinderash'),(PACKAGE/'share/wallpapers/CinderAsh',data/'wallpapers/CinderAsh'),(PACKAGE/'config/Kvantum/CinderAsh',config/'Kvantum/CinderAsh')]
 for src,dst in targets:
  if dst.is_symlink():raise RuntimeError('Refusing symlink destination: '+str(dst))
  if dst.exists() and not (existing and existing.get('installed')):raise RuntimeError('Destination already exists without a Cinder Ash install record: '+str(dst))
 if not existing or not existing.get('installed'):
  backup_dir=state_root/('sddm-' if system else 'user-')/str(time.time_ns());backup_dir.mkdir(parents=True,exist_ok=True);backup_dir.chmod(0o700)
  files=[config/'sddm.conf'] if system else [config/n for n in ['kdeglobals','plasmarc','kwinrc','ksplashrc','kscreenlockerrc','Kvantum/kvantum.kvconfig']]
  state={'version':VERSION,'installed':True,'configs':snapshot(files,backup_dir),'files':{},'dirs':[],'wallpapers':[],'portal_overrides':[]}
 else:
  state=existing
  # Preserve the first backup across repeat installs.
 if system and not stage and not shutil.which('sddm-greeter-qt6'):raise RuntimeError('Qt 6 SDDM greeter is required; install it before applying this login theme.')
 try:
  for src,dst in targets:
   if src.is_dir():state['dirs'].append(str(dst))
   pairs=[(src,dst)] if src.is_file() else [(p,dst/p.relative_to(src)) for p in src.rglob('*') if p.is_file()]
   for source,target in pairs:
    if target.is_symlink():raise RuntimeError('Refusing symlink destination: '+str(target))
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,target);target.chmod(0o644);state['files'][str(target)]=digest(target)
  if system:
   # sddm.conf has higher priority than conf.d. Change only Theme/Current.
   set_key(config/'sddm.conf',['Theme'],'Current','CinderAsh')
   print('Cinder Ash 0.01 SDDM theme installed. It takes effect at the next login; the display manager was NOT restarted.')
  else:
   # Disable only our earlier Ambinance workaround; keep that separate theme intact.
   for service in ['plasma-xdg-desktop-portal-kde.service','xdg-desktop-portal-kde.service']:
    p=config/'systemd/user'/f'{service}.d'/'90-ambinance-classic-toolbar.conf'
    if p.is_file() and p.read_text().startswith('# Managed by Ambinance Classic: file-dialog toolbar override'):
     state['portal_overrides'].append({'path':str(p),'text':p.read_text(),'service':service});p.unlink()
     if not stage and shutil.which('systemctl'):
      run(['systemctl','--user','daemon-reload'],False);run(['systemctl','--user','try-restart',service],False)
   activate_user(data,config,state,stage)
   print('Cinder Ash 0.01 installed. Icons, cursors, font settings and desktop layout were not changed.')
 finally:
  for e in state['configs']:e['after']=digest(Path(e['path']))
  state_root.mkdir(parents=True,exist_ok=True);state_file.write_text(json.dumps(state,indent=2));state_file.chmod(0o600)
  print('Backup/rollback record:',state_file)

def uninstall(stage,system):
 data,config,state_root=paths(stage,system);state_file=state_root/('sddm.json' if system else 'user.json')
 if not state_file.exists():print('No Cinder Ash installation record found; nothing removed.');return
 state=json.loads(state_file.read_text())
 if not state.get('installed'):print('Cinder Ash is already removed; backups retained.');return
 # Preflight every file before restoring anything, so refusal is transactional.
 skipped=[e['path'] for e in state['configs'] if digest(Path(e['path']))!=e.get('after')]
 if skipped:
  print('Settings changed since installation. Nothing removed or restored.\nChoose a replacement theme and review these files/backups before removal:\n'+'\n'.join(skipped));return
 if not system and not stage and state.get('wallpapers'):
  old=json.dumps(state['wallpapers']);current=json.dumps(state.get('wallpaper_applied',''))
  desktop_script('var old='+old+';var ds=desktops();for(var i=0;i<ds.length;i++){var d=ds[i];d.currentConfigGroup=["Wallpaper",d.wallpaperPlugin,"General"];if(d.readConfig("Image","")==='+current+'){for(var j=0;j<old.length;j++){if(old[j].id===d.id){d.wallpaperPlugin=old[j].plugin;d.currentConfigGroup=["Wallpaper",d.wallpaperPlugin,"General"];d.writeConfig("Image",old[j].image);}}}}')
 for e in state['configs']:
  p=Path(e['path'])
  if e['before'] is None:p.unlink(missing_ok=True)
  else:shutil.copyfile(e['backup'],p);p.chmod(e['mode'])
 for name,expected in state['files'].items():
  p=Path(name)
  if p.is_file() and not p.is_symlink() and digest(p)==expected:p.unlink()
  elif p.exists():print('Kept modified theme file:',p)
 for directory in set(state['dirs']):
  p=Path(directory)
  if p.is_dir():
   for d in sorted([x for x in p.rglob('*') if x.is_dir()],key=lambda x:len(x.parts),reverse=True):
    try:d.rmdir()
    except OSError:pass
   try:p.rmdir()
   except OSError:pass
 for e in state.get('portal_overrides',[]):
  p=Path(e['path'])
  if not p.exists():
   p.parent.mkdir(parents=True,exist_ok=True);p.write_text(e['text'])
   if not stage and shutil.which('systemctl'):
    run(['systemctl','--user','daemon-reload'],False);run(['systemctl','--user','try-restart',e['service']],False)
 state['installed']=False;state_file.write_text(json.dumps(state,indent=2));state_file.chmod(0o600)
 print('Cinder Ash 0.01 removed; previous unchanged settings restored. Backups retained.')
 if not system:print('Log out and back in to reload the restored desktop appearance.')

if __name__=='__main__':
 p=argparse.ArgumentParser(description='Cinder Ash 0.01 — MisterKnot — https://github.com/MisterKnot')
 p.add_argument('action',choices=['install','uninstall','install-sddm','uninstall-sddm'])
 p.add_argument('--staging-root',type=Path,help='Isolated packaging-test destination; never runs desktop commands.')
 a=p.parse_args();system=a.action.endswith('sddm')
 if not a.staging_root and system and os.geteuid()!=0:p.error('SDDM installation/removal requires administrator privileges.')
 if not a.staging_root and not system and os.geteuid()==0:p.error('Run the desktop installer as your normal user, without sudo.')
 try:(uninstall if a.action.startswith('uninstall') else install)(a.staging_root,system)
 except (OSError,RuntimeError,ValueError) as e:print('Cinder Ash:',e,file=sys.stderr);sys.exit(1)
