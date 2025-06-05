#
#
# QCanvas2d - main driver
#
# Copyright © Philip Quaife 1 Jan 2006
#

 variable Home

set Home [file dirname [info script]]

proc alias {cmd args} {	
	puts "ALIAS: uplevel 1 interp alias {{}} [expr {[string range $cmd 0 1] eq {::} ? {} : "[nc]::"}]$cmd {{}} [expr {[string range [lindex $args 0] 0 1] eq {::} ? {} : "[nc]::"}]$args "
	uplevel 1 interp alias {{}} [expr {[string range $cmd 0 1] eq {::} ? {} : "[nc]::"}]$cmd {{}} [expr {[string range [lindex $args 0] 0 1] eq {::} ? {} : "[nc]::"}]$args 
}

uplevel #0 {
package require tcl3d
if {[info command togl3d] eq {}} {
	rename togl togl3d
}
}

proc canvasgl {args} {
  variable canvas
  variable optiondb
  variable itemoptiondb
  variable Home
  catch {unset optiondb}
  catch {unset canvas}

  package require Tk


  interp alias {} [namespace current]::nc {} ::namespace current
  destroy .___c___ .___t___
  ::togl3d .___t___
  foreach o [.___t___ configure] {
    foreach {opt - - - val} $o break
	lappend canvas(togldelegate) $opt
	set canvas($opt) $val
	set optiondb($opt) [lrange $o 1 end]
  }
  if {[info commands oldcanvas] ne {}} {
	  oldcanvas .___c___
  } else {
	  ::canvas .___c___
  }
  foreach o [.___c___ configure] {
    foreach {opt - - - val} $o break
	set canvas($opt) $val
	lappend canvas(canvasdelegate) $opt
	set optiondb($opt) [lrange $o 1 end]
  }
  destroy .___c___ .___t___

  array set canvas {
		eventprocs {}
		viewscale {1 1 1}
 }

 set optiondb(-initialvlistsize) {{} {} 10 10}
 set optiondb(-initialitemsvlistsize) {{} {} 200 200}
 set canvas(-initialvlistsize) 10
 set canvas(-initialitemsvlistsize) 200
 set canvas(fonts) {}

 alias xview  //view x 
 alias yview  //view y
 alias -bg //reconf -background
 alias cc ::clock clicks -milli

 alias primative ::namespace inscope primatives
 namespace eval primatives {}

 namespace eval Shapes {namespace eval primatives {}}

 foreach f [glob $Home/*.qgl] {
	namespace inscope primatives source $f
 }
   array set itemoptiondb {
        -fill black
        -width 1 
        -scale {1 1}
        -rotation 0
        -rotationY 0
        -rotationX 0
        -translation {0 0}
        -anchor nw
        -outline black
        -layer 50
        -alpha 1
        -tags {}
		-group CanvasItems
		-state normal
		-smooth false
		-blend false
		-gltexture {}
		image {-image {} -width 0 -height 0 -tile {} -fill white}
		text  {-text {} -justify left -font {default 12 normal} -anchor c -texture {} -depthhint {} }
		line  {-activedash {} -disableddash {} -dashoffset {}}
		rectangle {-roundedcorners false}
		oval {-start 0 -extent 360 -style pieslice}
		arc {-start 0 -extent 360 -style pieslice}
		polygon {-convex false}
		cube {-group Canvas3DItems}
		group {-groupname {}}
		chain {-dlists {}}
   }
	interp alias {} q {} namespace inscope Qcanvas2d

	foreach f [glob *.tk] {
		uplevel #0 namespace inscope [nc] source [list $Home/$f]
	}
	namespace inscope primatives source $Home/primatives.qgl

 //abbrev configure itemconfigure itemcget yview xview \
	create coords delete find move scale
 rename canvasgl {}
 rename canvasglX  canvasgl
 uplevel 1 [namespace current]::canvasgl $args

}

proc extend {name arglist body} {	proc [nc]::$name $arglist $body }

proc -width  {path old new} {$path/togl configure -width $new}
proc -height {path old new} {$path/togl  configure -height $new}
proc -yscrollcommand {path old new} {}
proc -scrollregion {path old new} {//view - $path configure scrollregion}
proc -bg {path old new} {configure $path -background $new}

proc //reflect {path cmd args} { uplevel 1 namespace inscope [namespace current] $cmd $path $args}


# proc //reflect {args} {uplevel 1 [nc]:://reflectXX $args }

proc makecurrent {path args} {$path/togl makecurrent}
proc render {path args} {$path/togl render}

proc togl {path args} {
	if {! [llength	$args]} {return $path}
	uplevel 1 $path $args 
}

proc rlevel {path args} {

	puts "level [info level]"
	puts "cmd [info level -1]"
	catch {puts "cmd [info level -2]"}
	set x 1
	set y 2
	puts "Locals [info locals]"
	define $path 99 {
		puts "def cmd [info level 0]"
		set x  $y
		set y	$x
	}
	$path define 99 {

		set x  $y
		set y	$x
	}

}

proc canvasglX {path args} {
	variable canvas
	variable Home

	foreach a [info vars [nc]::$path/*] {
		unset $a
	}
	upvar [nc]::$path/togl widget
	upvar [nc]::$path/items items
	upvar [nc]::$path/tags tags
	upvar [nc]::$path/bindings bindings

		
	catch {unset widget}
	catch {unset items}
	catch {unset tags}
	catch {unset bindings}

	array set widget [array get canvas -*]
	array set widget "
		name $path 
		created [clock seconds]
		togl  $path/togl
		yview 0
		xview 0
		yoffset 0
		xoffset 0
		glenables {}
		compbbox {}
		fonttypes txf		
		fontpath $Home/data
		Fov 60 Ratio 1
		fonts {}
	"
	if {! [catch {package require zlib}] } {
		set widget(fonttypes) [concat qfnt $widget(fonttypes)]
	}
	if {[tcl3dHaveFTGL]} {
		set widget(fonttypes) [concat ttf $widget(fonttypes)]
	}

	set items(all) {}
	set tags(current) {}
	catch {destroy ::$path/togl}

	togl3d $path -depth true -alpha true -stencil 1 -stencilsize 1 -double true -displayproc [nc]::/togldisplay 

	set canvas(toplevel) [winfo toplevel $path]

	rename ::$path ::$path/togl
	alias ::$path [nc]:://reflect $path 

	$path xview moveto 0
	$path yview moveto 0

	/toglcreate $path

	uplevel #0 $path configure $args
	$path/togl configure -reshapeproc [nc]::/toglreshape  

	/setup $path
	/toglreshape $path/togl
	return $path
}

proc /setup {path} {

	/bindinit $path
	trace add command ::$path delete "[nc]::/cleanup $path"
	foreach b {1 2 3 4} {
		::bind $path <ButtonRelease-$b> "[nc]::/bindcurrent $path 0 %x %y"
	}
}

proc /cleanup {path args} {
	upvar [nc]::$path/togl widget

	foreach f $widget(fonts) {
		catch {unset [nc]::$path/$f}
	}
	### FIX ME: Clean up vectors
	foreach v $widget(vlists) {
		catch {delete_GLint $v}
	}
	catch {delete_GLint $widget(viewvector)}
	catch {unset [nc]::$path}
	catch {unset [nc]::$path/items}
	catch {unset [nc]::$path/tags}
	catch {unset [nc]::$path/bindings}
}

proc configure {path args} {
	variable optiondb

puts "CONFIG $path"

	upvar [nc]::$path/togl widget

	if {! [llength $args] } {
		set ret [list]
		foreach {name value} [array get widget -*] {
			if {[llength $optiondb($name)] < 3} {
				lappend ret [list $name $name $name $value]
			} else {
				lappend ret [concat $name [lreplace $optiondb($name) 3 3 $value]]
			}
		}
		return $ret
	}

	if { [llength $args] == 1} {
		set name [lindex $args 0]
		if {[llength $optiondb($name)] < 3} {
			return [list $name $name $name $value]
		} else {
			return [concat $args [lreplace $optiondb($args) 3 3 $widget($args)]]
		}
	}

	set update [list]
	foreach {name value} $args {
		lappend update $name [expr {[info exist widget($name)]? $widget($name) : {{}} }] $value
		set widget($name) $value
	}
	foreach {name oldvalue newvalue} $update {
		if { $oldvalue != $newvalue} {
			if { [info command $name] == {} } {continue}
			if { [catch {$path $name $oldvalue $newvalue} err] } {
				puts "Error $err $::errorInfo"
			}
		}
	}
	idleupdate $path
}

proc cget {path what args} {

	upvar [nc]::$path/togl qdb

	if { [llength $args] } {
		set qdb($what) [lindex $args 0]
	}
	set qdb($what)
}

proc //view {dir path args} {
	upvar [nc]::$path/togl canvas


	set ret 0

	puts "VIEW $path event Scroll $dir $args"

	if {! [llength $args]} {
		return $canvas(${dir}view)
	}
	set cmd [lindex $args 0]
	set args [lrange $args 1 end]


	set bb [$path cget -scrollregion]
	if {[llength $bb] < 4} {return}
	foreach {x1 y1 x2 y2} $bb break
	set offy $canvas(yoffset)
	set offx $canvas(xoffset)

	set rangey [expr {$y2 - $y1}]
	set rangex [expr {$x2 -$x1}]

	set w [winfo width $path]
	set h [winfo height $path]
	if {$cmd eq {configure} } {
		//view x $path moveto 0.5		
		//view y $path moveto 0.5		
		return
	}
	if {[lsearch {moveto scroll} $cmd] > -1} {
	foreach {amt unit} $args {break}
	switch -- $dir$cmd {
		xscroll {		}
		xmoveto {		
			set offx [expr {int($amt * $rangex)}]
			if {$offx < 0} {set offx 0}
			if { $offx + $w <= $rangex} {
				set canvas(xoffset) $offx
			} else {
				set offx $canvas(xoffset)
			}
		}
		yscroll {		}
		ymoveto {
			set offy [expr {int($amt * $rangey )}]
			if {$offy < 0} {set offy 0}
			if { $offy + $h <= $rangey} {
				set canvas(yoffset) $offy
			} else {
				set offy $canvas(yoffset)
			}
		}
	}

	define $path CanvasView {
		glTranslatef [expr {-$offx - $x1}] [expr {-$offy - $y1}]   0
	}
	}

	set xr1 [expr {double($offx)/ $rangex}]
	set xr2 [expr {double($offx+$w)/ $rangex}]
	set yr1 [expr {double($offy)/ $rangey}]
	set yr2 [expr {double($offy+$h)/ $rangey}]
	set yr2 [expr {$yr2> 1.0 ? 1.0 : $yr2}]
	set xr2 [expr {$xr2> 1.0 ? 1.0 : $xr2}]
	set yr1 [expr {$yr1 < 0.0 ? 0.0 : $yr1}]
	set xr1 [expr {$xr1 < 0.0 ? 0.0 : $xr1}]

	foreach v {xr1 xr2 yr1 yr2} {set $v [expr {round([set $v] * 100)/100.0}] }

	set canvas(xview) [list $xr1 $xr2]
	set canvas(yview) [list $yr1 $yr2]
	if {$canvas(-yscrollcommand) ne {}} {
		eval $canvas(-yscrollcommand) $yr1 $yr2
		after idle "$canvas(-yscrollcommand) $yr1 $yr2"
	}
	if {$canvas(-xscrollcommand) ne {}} {
		eval $canvas(-xscrollcommand) $xr1 $xr2
	}
	$path idleupdate
	set ret
}


proc //reconf {what path old new} {

	lappend paths $path
	while {[llength $paths] } {
		set p [lindex $paths 0]
		set paths [lrange $paths 1 end]
		$p configure $what $new 
		eval	lappend paths [winfo children $p]
	}
}

proc event {path what args} {
  upvar [namespace current]::$path qdb

	foreach ev $qdb(eventprocs) {
		namespace inscope [namespace current] $ev $path $what $args
	}
	list
}

## Item Bounding boxes

proc /enlarge {size coords}  {

	if {[llength $size] < 4 } {
		set size [string repeat "$size " 4]
	}
	foreach {sizex1 sizey1 sizex2 sizey2} $size {break}

	foreach {x1 y1 x2 y2} $coords {break}

	list [expr {$x1 - $sizex1}] \
		 [expr {$y1 - $sizey1}] \
		 [expr {$x2 + $sizex2}] \
		 [expr {$y2 + $sizey2}] 
}


proc /bbox {path what rowcol } {
	switch $what {
		cell {
			[$path canvas] bbox data-$rowcol
		}
		row {
			[$path canvas] bbox row/$rowcol
		}
		col {
			[$path canvas] bbox col/$rowcol
		}
		data {
			[$path canvas] bbox data
		}
		all {
			[$path canvas] bbox GRID
		}
		default {
			[$path canvas] bbox $what
		}
	}
}


proc value {path x y args} {
  upvar [namespace current]::$path qdb

	set idx [expr {$qdb(-columncount) * $x + $y}]

	set value [lindex $qdb(-data) $idx]
	if {[llength $args]} {
		lset qdb(-data) $idx [lindex $args 0]
		$path event UpdateCell $x $y $value [lindex $args 0]
		[$path canvas] itemconfigure data-$x.$y -text [$path formatcell $y [lindex $args 0]]
		$path layout cell $x $y
	}
	set value
}

proc /dataclick {path x y} {
  upvar [namespace current]::$path qdb

	if {! [info exists qdb(lastclickrow)] } {
			set qdb(lastclickrow) {}
	}

	set row {}
	set col {}

	foreach {row col} [$path gridref $x $y] {break}
 	set id [[$path canvas] find withtag data-$row.$col]
	if {$id == {}} {return}
	$path editstate reset
	$path event [expr {$row == $qdb(lastclickrow) ? {SelectCell} : {SelectRow} }] $row $col $x $y
	set qdb(lastclickrow) $row
	list
}


proc /keypress { path k c} {
  upvar [namespace current]::$path qdb

  set w [$path canvas]

  set tag $qdb(selectedtag)
  switch $k {
    Shift_R - Shift_L {}
    Meta_L - Meta_R - Alt_L - Alt_R - Control_L -  Control_R - Prior - Next {}
	Return {
         $w insert $tag insert \n
         set vw(edtChanged) 1
	}
    BackSpace {
       set dp [expr [$w index $tag insert] - 1]
       if {$dp >= 0} {
          $w dchars $tag $dp $dp
          set vw(edtChanged) 1
       }
      }
    Delete {      
       set dp [expr [$w index $tag insert] ]
       $w dchars $tag $dp $dp
       set vw(edtChanged) 1
      }
    Home  { $w icursor $tag 0 }
    End   { $w icursor $tag end }
    Left  { $w icursor $tag [expr [$w index $tag insert] - 1] }
    Right { $w icursor $tag [expr [$w index $tag insert] + 1]  }
	Up {
		set p [$w index $tag insert]
#		incr p -1
		set txt [$w itemcget $tag -text]
		set pos [string last \n $txt $p]
		if {$pos != -1} {$w icursor $tag [incr pos -1]}
		if {$p && $pos == -1} {$w icursor $tag 0}
	}
	Down {
		set p [$w index $tag insert]
#		incr p
		set txt [$w itemcget $tag -text]
		set pos [string first \n $txt $p]
		if {$pos != -1} {$w icursor $tag [incr pos]}
		if {$p && $pos == -1} {$w icursor $tag end}
	}
    default {
       set c [string range $c end end]
       if {[string compare "$c" " "] > -1} {
         $w insert $tag insert "$c"
         set qdb(edit) [clock seconds]
       }
      }
  }
  $path editstate key 

  list
}

proc editstate {path state args} {
  upvar [namespace current]::$path qdb

  set c [$path canvas]

  switch $state {
	reset {
	  $c delete insertunderlay
	  if {[info exists qdb(selectedtag)]} {
	  $c bind $qdb(selectedtag) <Key> {}
	  $c bind $qdb(selectedtag) <Control-Key-Return> {}
	  $c bind $qdb(selectedtag) <Key-Return> {}
	  $c bind $qdb(selectedtag) <Key-Escape> {}
	  $c bind $qdb(selectedtag) <Button-1> {}
	  }
	  $c focus {}
	  focus [winfo parent $c]
	}
	cancel {
	    foreach {row col} [split $qdb(selectedcell) .] {break}
		$path editstate reset
		$c itemconfigure $qdb(selectedtag) -text [$path formatcell $col [$path value $row $col]]
	    $c raise $qdb(selectedtag) text
	}
	end {
      foreach {row col} [split $qdb(selectedcell) .] {break}
	  $path editstate reset
	  $c raise $qdb(selectedtag) text
	  if {$state == {end}} {
	    $path value $row $col [$c itemcget $qdb(selectedtag) -text]
	    $path event SelectRow $row $col 0 0
	  } 
	}
	start {
	    foreach {row col} [split $qdb(selectedcell) .] {break}
		foreach {x y} $args {break}
		$c itemconfigure $qdb(selectedtag) -text [$path value $row $col]
		$c focus $qdb(selectedtag)
		$c bind $qdb(selectedtag) <Button-1> break
		$c bind $qdb(selectedtag) <Key> [namespace code "/keypress $path  {%K} {%A}; break"]
		$c bind $qdb(selectedtag) <Control-Key-Return> [namespace code "/keypress $path Return {};break"]
		$c bind $qdb(selectedtag) <Key-Return> "[namespace code "$path editstate end"];break"
		$c bind $qdb(selectedtag) <Key-Escape> "[namespace code "$path editstate cancel"];break"
		set cx [$c canvasx $x]
		set cy [$c canvasy $y]
		if {$qdb(-canvasbug)} {
			foreach {x1 y1 } [$c cget -scrollregion] {break}
			set cx [expr {$cx - $x1}]
			set cy [expr {$cy - $y1}]
		}
		$c icursor $qdb(selectedtag) @$cx,$cy
		$path bbox cell $row.$col x1 y1 x2 y2
		$path bbox col $col x1 - x2 -
		$c delete "GRID && insertunderlay"
		$c create rectangle $x1 $y1 $x2 $y2 \
			-tags "GRID insertunderlay " \
			-fill white \
			-outline red \
			-width 2
		$c raise insertunderlay
		$c lower insertunderlay overlay
		$c raise $qdb(selectedtag) overlay
		$path editstate key ?
		focus $c
	}
	key {
	  set coords [$path /bbox $qdb(selectedtag) -]
	  $c coords insertunderlay  [/enlarge 5 $coords]
	}
  }
}

proc /Events {path what args} {
  upvar [namespace current]::$path qdb

#	puts "Event $path ${what}($args)"
	set c [$path canvas]
	switch $what {
		<Configure> {
			set bbox [$c bbox GRID]
			if { [llength $bbox]} {
				$c configure -scrollregion [/enlarge {0 0 20 50} $bbox]
			}
			set bb [$c bbox HeaderBG]
			if { [llength $bb] } {
				lset bb 2 [winfo width $c]
				$c coords HeaderBG 	$bb
			}
		}
		Layout {
			set x1 {}
			foreach {x1 y1 x2 y2} [/enlarge {0 0 20 10} [$c bbox GRID&&datatext]] {break}
			if {$x1 eq {}} {return}
			if {$qdb(-autosize) == {width} || $qdb(-autosize) == {both} } {
				$c configure -width [expr {$x2 - $x1}]
			}
			if {$qdb(-autosize) == {height} || $qdb(-autosize) == {both} } {
			  if { $qdb(-maxheight) && ($y2-$y1) > $qdb(-maxheight) } {
				set y2 [expr {$qdb(-maxheight) + $y1}]
			  }
			  $c configure -height [expr {$y2 - $y1}]
			}
		}
		SelectCell {
			foreach {row col x y} [lindex $args 0] {break}
			set qdb(selectedcell) [list $row.$col]
			#set qdb(selectedtag)  [$c find withtag data-$row.$col]
			set qdb(selectedtag)  data-$row.$col
			$path editstate start $x $y
		}
		SelectRow {
			foreach {row col x y} [lindex $args 0] {break}
			set selid [$c	find withtag rowselection]
			if {$selid == {} } {
				set selid [ \
				$c create rectangle 0 0 0 0 \
					-tags "GRID rowselection" \
					-fill white \
					-outline {}]
				$c raise $selid 
				$c lower $selid text
			}
			foreach {x1 y1 x2 y2} [$path /bbox row $row] {break}
			set x1 [$c canvasx 0]
			set x2 [winfo width $c]
			$c coords $selid [/enlarge [list 0 0 $qdb(-columnpad) $qdb(-columnpad)] [list $x1 $y1 $x2 $y2]]
		}
		DeleteSelection {
		  [$path canvas] delete rowselection
		  set qdb(lastclickrow) {}
		}
		Scroll {
		
		  set x1 [expr {int([$c canvasx 0])}]
		  set y1 [expr {int([$c canvasy 0])}]
		  if {! $qdb(-floatheader) } {
			set x1 0
			set y1 0
		  }
		  ## FIX ME : need to absolute align columns
		  set x1 $qdb(-columnpad)
	      incr x1 $qdb(-columnpad)

		  set cx {}
		  foreach {cx cy} [$c bbox GRID&&HeaderText] {break}
		  if {$cx != {}} {
		    $c move GRID&&Header [expr {$x1 -$cx}] [expr {$y1 - $cy}]
		  }

		}
	}
}

proc /toglreshape {path} {
puts "RESHAPE $path "

	upvar [nc]::$path canvas

	set path $canvas(name)

	set w $canvas(togl)

  set width [$w width]
  set height [$w height]
	set canvas(viewport) [list $width $height]
	glNewList [$path ~=  ViewPort] GL_COMPILE_AND_EXECUTE
      glViewport 0 0 $width $height
	glEndList
	glNewList [$path ~ Perspective] GL_COMPILE_AND_EXECUTE
      glMatrixMode GL_PROJECTION
      glLoadIdentity
      gluPerspective $canvas(Fov) $canvas(Ratio) -511 512
#	  glFrustum 0 $width 0 $height 0 1000
	
      glMatrixMode GL_MODELVIEW
#	  glCallList [$path ~ CanvasView]
	glEndList
	set canvas(PerspectiveMatrix) [$path glquery PROJECTION_MATRIX 16]
	glNewList [$path ~ Orthographic] GL_COMPILE_AND_EXECUTE
      glMatrixMode GL_PROJECTION
      glLoadIdentity
	  glOrtho 0 $width $height 0 -127 128
      glMatrixMode GL_MODELVIEW
    glEndList
   	set canvas(OrthoMatrix) [$path glquery PROJECTION_MATRIX 16]
    glGetIntegerv GL_VIEWPORT $canvas(viewvector)
puts "RESH DONE"
	list
}

proc /toglcreate { path } {
	upvar [nc]::$path/togl canvas

# Apparently we are here before canvasgl proc finishes.

	set w $canvas(togl)

#	rename ::$path [nc]::$path/togl
#	alias $path //reflect $path
	set canvas(objects) {}
	set canvas(viewvector) [new_GLint 4]

puts "CREAT $path"
	glNewList [$path ~= BLANK] GL_COMPILE
	glEndList
	glNewList [$path ~= NOTEXTURE] GL_COMPILE
	glEndList
	glNewList [$path ~= Identity] GL_COMPILE
		glLoadIdentity
	glEndList
puts "ST2"
	set canvas(scene) {GLEnviron GLEnables Orthographic Background CanvasView CanvasItems Perspective Camera Canvas3DItems Orthographic Identity OverLay Effects}
	$path vlist create Canvas $canvas(-initialvlistsize)
	foreach dlist $canvas(scene) {
		$path ~= $dlist
		$path vlist add Canvas $dlist 
	}
	$path vlist create CanvasItems   $canvas(-initialitemsvlistsize)
	$path vlist create Canvas3DItems $canvas(-initialitemsvlistsize)
	$path vlist create Background
	$path vlist create Overlay

	glNewList [$path ~= Select] GL_COMPILE
	  glCallList [$path ~ CanvasView]
	  glCallList [$path ~ CanvasItems]
	glEndList
	glNewList [$path ~= Camera] GL_COMPILE
		glTranslatef 0 0 -700
	glEndList
	glNewList [$path ~= GLEnviron] GL_COMPILE
	  glBlendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
	glEndList

	glNewList [$path ~= NOTEXTURE] GL_COMPILE_AND_EXECUTE
		glDisable GL_TEXTURE_GEN_S
		glDisable GL_TEXTURE_GEN_T
		glDisable GL_TEXTURE_2D
		glBindTexture GL_TEXTURE_2D 0
	glEndList

	$path idleupdate
puts "CREA END [winfo child .]"
list
}

# This is were we loop through our display list and draw the objects.
proc /togldisplay { path } {
	upvar [nc]::$path canvas

	#puts "TDISP $path"
	set path $canvas(name)

	if {! [winfo ismapped $path] } {
		return {}
	}
    glMatrixMode GL_MODELVIEW
    glLoadIdentity
		glClearColor {*}[/rgb [$path cget -background]  1] 
    glClear [expr $::GL_COLOR_BUFFER_BIT | $::GL_DEPTH_BUFFER_BIT]

	glDisable GL_TEXTURE_2D

	glCallList [$path ~ Canvas]

	$canvas(togl) swapbuffers

}


namespace export canvasgl



#package provide canvas25d 1.0












