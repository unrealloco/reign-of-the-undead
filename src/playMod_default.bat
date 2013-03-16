@echo off
cd ..\..\

iw3mp.exe +set dedicated 2 +set fs_game "mods\rotudev" +set sv_punkbuster 0 +set developer 0 +set ui_maxclients 40 +set sv_maxclients 40 +set developer_script 0 +set dedicated 0 +set g_gametype "surv" +set game_difficulty 4 +set net_ip 24.16.49.142 +set net_port 28960 +exec server.cfg +devmap mp_fnrp_bridge
rem mp_surv_isle
rem mp_surv_oldwest_v2
rem mp_surv_gold_rush
rem mp_fnrp_quake3_arena
rem mp_fnrp_bridge
