# This is makeConfig.pl

# The full path to your cod install
codPath     => 'C:\Program Files (x86)\Activision\CoD4-1.6',

# The full path where the compiled code will reside
modPath     => 'C:\Program Files (x86)\Activision\CoD4-1.6\Mods\rotudev',

# The full path to a convienent folder for ftp'ing the server files to the server
uploadPath  => 'C:\Users\Mark\Desktop\rotudevUpload',

# If you add/remove config files, update this array so makeMod.pl works properly!
configFiles => ['admin.cfg', 'damage.cfg', 'didyouknow.cfg', 'easy.cfg',
                'mapvote.cfg', 'server.cfg',
                'weapons.cfg'],