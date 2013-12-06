# Conky, a system monitor, based on torsmo
#
# Any original torsmo code is licensed under the BSD license
#
# All code written since the fork of torsmo is licensed under the GPL
#
# Please see COPYING for details
#
# Copyright (c) 2004, Hannu Saransaari and Lauri Hakkarainen
# Copyright (c) 2005-2010 Brenden Matthews, Philip Kovacs, et. al. (see AUTHORS)
# All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

alignment top_left
background no
border_width 1
cpu_avg_samples 2
default_color white
default_outline_color white
default_shade_color white
draw_borders no
draw_graph_borders yes
draw_outline no
draw_shades no
use_xft yes
xftfont DejaVu Sans Mono:size=8
gap_x 5
gap_y 60
minimum_size 5 5
net_avg_samples 2
no_buffers yes
out_to_console no
out_to_stderr no
extra_newline no
own_window yes
own_window_class Conky
#own_window_type desktop
own_window_type normal
stippled_borders 0
update_interval 1.0
uppercase no
use_spacer left
show_graph_scale no
show_graph_range no

lua_load .scripts/conkybitcoin.lua
color0 grey
color1 white
color2 FF0000
color3 00FF00

TEXT
${image /home/rena/img/anime/digimon/renamon/bgcrap/renamon-mod1-fone.png -p -50,-20 -s 362x642}$nodename - $sysname $kernel
$hr
${color0}Up $color$uptime - ${color0}CPU Freq: $freq ${color0}MHz
${color0}RAM:$color $mem/$memmax - $memperc% ${membar 4}
${color0}CPU:$color $cpu% ${cpubar 4}
${color0}Processes:$color $processes  ${color0}Running:$color $running_processes
${color0}Net: Up:$color ${upspeed eth0} ${color0} - Down:$color ${downspeed eth0}
$hr
${color0}File systems:
 /     $color${fs_used /}/${fs_size /} ${fs_bar 6 /}
 /boot $color${fs_used /boot}/${fs_size /boot} ${fs_bar 6 /boot}
 /var  $color${fs_used /var}/${fs_size /var} ${fs_bar 6 /var}
 /home $color${fs_used /home}/${fs_size /home} ${fs_bar 6 /home}
$hr
${color0}Name              PID   CPU%   MEM%
${color lightgrey} ${top name 1} ${top pid 1} ${top cpu 1} ${top mem 1}
${color lightgrey} ${top name 2} ${top pid 2} ${top cpu 2} ${top mem 2}
${color lightgrey} ${top name 3} ${top pid 3} ${top cpu 3} ${top mem 3}
${color lightgrey} ${top name 4} ${top pid 4} ${top cpu 4} ${top mem 4}
$hr
${lua_parse bitcoin_balance} BTC$color, ${lua_parse bitcoin_info ${color1}<blocks>${color0} blocks, ver ${color1}<version>}${color0}
Recent transactions:
 ${lua_parse bitcoin_transaction 1 "*" ${color1}<time> <amount>${color1} <account>}
 ${lua_parse bitcoin_transaction 2 "*" ${color1}<time> <amount>${color1} <account>}
 ${lua_parse bitcoin_transaction 3 "*" ${color1}<time> <amount>${color1} <account>}
$hr
${color0}Cur Buy        Sell       Avg
CAD ${lua_parse mtgox CAD ${color1}<buy> <sell> <avg>}${color0}
USD ${lua_parse mtgox USD ${color1}<buy> <sell> <avg>}
