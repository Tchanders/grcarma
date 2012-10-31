#!/usr/bin/perl

use strict;
use warnings;

# Use the Tk module for the GUI        #

use Tk;
use Tk::MsgBox;

require Tk::BrowseEntry;

# Import the following modules         #

use Cwd 'abs_path';
use Cwd;
use List::MoreUtils qw { uniq };

# Get the system time and modify it so #
# that it is human readable            #

my @now = localtime();
my $timeStamp = sprintf( "carma_temp_%02d.%02d.%04d_%02d.%02d.%02d", $now[3], $now[4]+1, $now[5]+1900, $now[2], $now[1], $now[0] );

# Declaration of the global scalars... #

our $flag = '';
our $custom_id_flag = '';
our $seg_id_flag = '';
our $index_seg_id_flag = '';
our $custom_selection = '';
our $all_done = '';
our $psf_button = '';
our $dcd_button = '';
our $have_files = '';
our $filetypes = '';
our $have_custom_psf = '';
our $dcd_count = -1;
our $atm_id_flag = '';
our $res_id_flag = '';
our $header = '';
our $rmsd_step = '';
our $active_run_buttons = '';
our $eig_play = '';
our $eig_play_vector = '';
our $eig_art = '';
our $eig_art_vectors = '';
our $eig_art_frames = '';
our $top_eig = '';
our $frame_eig1 = '';
our $resid_bar_count = 0;
our $index_bar_count = '';
our $resid_row = '';
our $resid_column = '';
our $index_row = '';
our $index_column = '';
our $f4_b = '';
our $dpca_run_button = '';
our $atm_id = '';
our $index_num_atoms = '';
our $dpca_frame = '';
our $dpca_frame_1 = '';
our $frame_sur2 = '';
our $cpca_frame = '';
our $cpca_frame_1 = '';
our $dpca_auto_entry;
our $dpca_auto_entry_num;
our $cpca_auto_entry;
our $cpca_auto_entry_num;

# ... global arrays and hashes         #

our (

	@seg_ids,			@unique_chain_ids,		@unique_atom_types,
	@dropdown,			@amplitudes,			@dropdown_value,
	@upper_res_limit,	@lower_res_limit,		@upper_fit_limit,
	@lower_fit_limit,	@frame_res1,			@frame_fit_index4,
	%num_residues,		%substitutions,
);

# If the OS is *nix/unix-like and the  #
# the folder "carma_results exists in  #
# the current working directory get    #
# it's size and store it in a scalar   #

my $wd_size = '';
my $ps_viewer = '';
my $pdb_viewer ='';

if ( $^O eq 'linux' ) {

	if ( -d "carma_results" ) {

		$wd_size = `du -hs carma_results`;
		chomp $wd_size;
		if ( $wd_size =~ /(\d*,?\d*.)/ ) {

			$wd_size = $1 . "B";
		}
	}

	# If any of the following programs #
	# is found in the /usr/bin folder  #
	# set it as the default .ps file   #
	# viewer                           #

	if ( -e "/usr/bin/evince" ) {

		$ps_viewer = "evince";
	}
	elsif ( -e "/usr/bin/gs" ) {

		$ps_viewer = "gs";
	}
	elsif ( -e "/usr/bin/display" ) {

		$ps_viewer = "display";
	}

	chomp $ps_viewer if ( $ps_viewer );

	if ( -e "/usr/bin/rasmol" ) {

		$pdb_viewer = 'rasmol';
	}
	elsif ( -e "/usr/bin/jmol" ) {

		$pdb_viewer = 'jmol';
	}
	elsif ( -e "/usr/bin/jmol" ) {

		$pdb_viewer = 'pymol';
	}

	chomp $pdb_viewer if ( $pdb_viewer );
}

# Do the same thing for windows        #

else {

	if ( -d "carma_results" ) {

		`dir carma_results /s /-c | find "File(s)" > dir.txt`;
		open WIN_DIR, "dir.txt" || die "win close\n";
		while ( <WIN_DIR> ) {

			if ( /\d* File...\s*(\d*)/ ) {

				$wd_size = int ( ( $1 / 1000000 ) + 0.5 ) . "MB";
			}
		}

		close WIN_DIR;
		unlink ( "dir.txt" );
	}
}

# check for input from terminal        #
# if two files are specified           #
# and they are a DCD and a PSF file    #

my $run_from_terminal = 0;
my $psf_file = '';
my $dcd_file = '';
my $dcd_name = '';

if ( @ARGV ) {

	if ( @ARGV == 2 ) {

		# regardless of which was specified    #
		# first store each of them in a file   #
		# and store the name of the .dcd file  #
		# in a variable                        #
		if ( $ARGV[0] =~ /\w*\.psf/ && ( $ARGV[1] =~ /\w*\/(\w*\.dcd)/ || $ARGV[1] =~ /\w*\\(\w*\.dcd)/ ) ) {

			$psf_file = abs_path( $ARGV[0] );
			$dcd_file = abs_path( $ARGV[1] );
			$dcd_name = $1;
		}
		elsif ( $ARGV[1] =~ /\w*\.psf/ && ( $ARGV[0] =~ /\w*\/(\w*\.dcd)/ || $ARGV[0] =~ /\w*\\(\w*\.dcd)/ ) ) {

			$psf_file = abs_path( $ARGV[1] );
			$dcd_file = abs_path( $ARGV[0] );
			$dcd_name = $1;
		}
		# or terminate with a help message     #
		else {

			die "\nUsage: grcarma file.psf file.dcd\n\n";
		}

		# remember that files were specified   #
		# from STDIN and invoke the PSF parser #
		# subroutine                   		   #
		$run_from_terminal = 1;
		&parser;
	}
	else {

		# else if number of files specified is #
		# not 2 terminate with a help message  #
		die "\nPlease specify one .psf and one .dcd file\n\n";
	}
}

###################################################################################################
###   Main Window                                                                               ###
###################################################################################################

# Draw the main window                 #
my $mw = MainWindow -> new( -title => 'grcarma', );

# Create the frame for the selection   #
# of files                             #
my $gui = $mw -> Frame();
$gui -> Label( -text => 'Please select a .psf and a .dcd file', ) -> pack;

# Draw the button for psf selection    #
$psf_button = $gui -> Button( -text => 'Browse for a .psf file',
							  -command => sub {

								  $psf_button -> configure( -state => 'disabled', );
								  &open_file ( "psf" );
							  }, )
							  -> pack( -side => 'left' );

# Draw the button for dcd selection    #
$dcd_button = $gui -> Button( -text => 'Browse for a .dcd file',
							  -command => sub {

								  $dcd_button -> configure( -state => 'disabled', );
								  &open_file ( "dcd" );
							  }, )
							  -> pack( -side => 'right' );

# Unless input is specified from STDIN #
# draw the frame for file selection    #
unless ( $run_from_terminal ) {

	$gui -> pack( -side => 'top',
				  -expand => 1,
				  -fill => 'both', );

	$mw -> update();

	my $x_position = int ( ( $mw -> screenwidth / 2 ) - ( $mw -> width / 2 ) );
	my $y_position = int ( ( ( $mw -> screenheight - 80 ) / 2 ) - ( $mw -> height / 2 ) );

	my $mw_position = "+" . $x_position . "+" . $y_position;

	$mw -> geometry ("$mw_position");
	$mw -> focusForce if ( $^O ne 'linux' );
}

###################################################################################################
###   Container Frame                                                                           ###
###################################################################################################

# Create the first frame ( container ) #
my $f0 = $mw -> Frame ();

# If files are specified from STDIN    #
# draw the container frame and proceed #
# normally                             #
if ( $run_from_terminal ) {

	$f0 -> pack( -side => 'top',
				 -expand => 1,
				 -fill => 'both', );
}
else {

	$mw -> waitVariable(\$have_files);
}

###################################################################################################
###   File Menu                                                                                 ###
###################################################################################################

# Create the menubar                   #
$mw -> configure( -menu => my $menubar = $mw -> Menu );

# Create the menubutton "File" and the #
# menubutton "help"                    #
my $file = $menubar -> cascade( -label => '~File');
my $help = $menubar -> cascade( -label => '~Help');

# Draw a separating line               #
$file -> separator();

# Create a command of the "file" menu- #
# button which terminates the program  #
$file -> command( -label => "Exit",
				  -underline => 1,
				  -command => [ $mw => 'destroy' ], );

###################################################################################################
###   Menubutton Frame                                                                          ###
###################################################################################################

# Draw the second frame ( menubuttons) #
# on top of the first one              #
my $f1 = $f0 -> Frame ( -borderwidth => 3,
                        -relief => 'groove',)
						-> pack ( -side => 'left',
								  -expand => 1,
								  -fill => 'both',);

#Draw the button for the rmsd menu...  #
my $rmsd_menu = $f1 -> Button( -text => 'RMSD Matrix',
							   -command => \&rmsd_window,
							   -width => 20, )
							   ->pack( -side => 'top',
									   -anchor => 'center' );

# ... the dpca menu	                   #
my $dpca_menu = $f1 -> Button( -text => 'Dihedral PCA',
							   -command => \&dpca_window,
							   -width => 20, )
							   ->pack( -side => 'top',
									   -anchor => 'center' );

# ... the cpca menu	                   #
my $cpca_menu = $f1 -> Button( -text => 'Cartesian PCA',
							   -command => \&cpca_window,
							   -width => 20, )
							   ->pack( -side => 'top',
									   -anchor => 'center' );

# ... the sorting menu	               #
our $sort_menu = $f1 -> Button( -text => 'Cluster analysis',
								-command => \&sort_window,
								-width => 20,
								-state => 'disabled', )
								->pack( -side => 'top',
										-anchor => 'center' );

# ... the eigen calculations menu	   #
my $eigen_menu = $f1 -> Button( -text => 'Eigen calculations',
								-command => \&eigen_window,
								-width => 20, )
								->pack( -side => 'top',
									   -anchor => 'center' );

# ... the var_covar matrix menu	       #
my $varcov_menu = $f1 -> Button( -text => 'VarCov matrix',
								 -command => \&varcov_window,
								 -width => 20, )
								 ->pack( -side => 'top',
										 -anchor => 'center' );

# ... the entropy menu	               #
my $entropy_menu = $f1 -> Button( -text => 'Solute entropy calculation',
								  -command => \&entropy_window,
								  -width => 20, )
								  ->pack( -side => 'top',
										  -anchor => 'center' );

# ... the fitting menu	               #
my $fitting_menu = $f1 -> Button( -text => 'Fit',
								  -command => \&fit_window,
								  -width => 20, )
								  ->pack( -side => 'top',
										  -anchor => 'center' );

# ... the index fitting menu	       #
my $fit_index_menu = $f1 -> Button( -text => 'Selective Fit',
								  -command => \&fit_index_window,
								  -width => 20, )
								  ->pack( -side => 'top',
										  -anchor => 'center' );

# ... the pdb menu                    #
my $pdb_menu = $f1 -> Button( -text => 'Extract PDB',
							  -command => \&pdb_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the average distances menu	  #
my $rms_menu = $f1 -> Button( -text => 'Ca - Ca distances',
							  -command => \&rms_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the gyration menu	              #
my $rgr_menu = $f1 -> Button( -text => 'Radius of gyration',
							  -command => \&rgr_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the distances menu	          #
my $dis_menu = $f1 -> Button( -text => 'Distances',
							  -command => \&dis_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the bending angles menu	      #
my $ang_menu = $f1 -> Button( -text => 'Bending Angles',
							  -command => \&bnd_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the torsion angles menu	      #
my $tor_menu = $f1 -> Button( -text => 'Torsion Angles',
							  -command => \&tor_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the map menu	                  #
my $map_menu = $f1 -> Button( -text => 'Map ion & water',
							  -command => \&map_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

# ... the surface area menu	          #
my $sur_menu = $f1 -> Button( -text => 'Surface area',
							  -command => \&sur_window,
							  -width => 20, )
							  ->pack( -side => 'top',
									  -anchor => 'center' );

$f1 -> Label( -text => "\n", ) -> pack( -side => 'top', );

# ... the image menu	               #
our $image_menu = $f1 -> Button( -text => 'View Images',
								-command => [ \&image_window ],
								-width => 20,
								-state => 'disabled', )
								->pack( -side => 'top',
										-anchor => 'center' );

# and the exit menu	                   #
my $exit_menu = $f1 -> Button( -text => 'EXIT',
							   -width => 20,
							   -command => \&exit, )
							   -> pack( -side => 'top',
										-anchor => 'center', );

###################################################################################################
###   Atmid Frame                                                                               ###
###################################################################################################

# Draw the third frame (atmids) on top #
# of the first                         #
my $f2 = $f0 -> Frame( -borderwidth => 3,
					   -relief => 'groove',)
					   ->pack( -side => 'top',
						       -expand => 1,
							   -fill => 'both',);
# Invoke the radiobuttons subroutine   #
&radiobuttons ( $f2 );

###################################################################################################
###   Segid Frame                                                                               ###
###################################################################################################

# Draw the fourth frame(segids) on top #
# of the first                         #
my $f3 = $f0 -> Frame( -borderwidth => 3,
					   -relief => 'groove',)
					   ->pack( -side => 'top',
							   -expand => 1,
						       -fill => 'both',);
# Invoke the checkbuttons subroutine   #
&checkbuttons ( $f3 );

###################################################################################################
###   Resid Frame                                                                               ###
###################################################################################################

# Draw the fifth frame (resids) on top #
# of the first                         #
my $f4 = $f0 -> Frame( -borderwidth => 3,
					   -relief => 'groove',)
					   ->pack( -side => 'top',
						       -expand => 1,
						       -fill => 'both',);
# Invoke the otherbuttons subroutine   #
&otherbuttons ( $f4 );

###################################################################################################
###   Textbox Frame                                                                             ###
###################################################################################################

# Draw the sixth frame(textbox) on top #
# of the first one and immediately     #
# after the fifth frame is drawn       #
my $f5 = $f0 -> Frame() -> pack( -after => $f1,
								 -side => 'left',
								 -fill => 'both',
								 -expand => 1, );

our $text = $f5 -> Scrolled( "Text",
						 -bg => 'black',
						 -fg => 'white',
						 -font => "monospace 10 bold",
						 -wrap => 'word',
						 -scrollbars=> 'e',
						 -width => 75,
						 -height => 26, )
						 ->pack();

$text -> configure( -height => 32, ) if ( $^O eq 'linux' );

# Define three colored text tags       #
# to be used for the text displayed    #
# in the textbox                       #
$text -> tagConfigure( "error", -foreground => "red3" );
$text -> tagConfigure( "valid", -foreground => "green3" );
$text -> tagConfigure( "info", -foreground => "orange1" );

# Also tie the STDOUT to the textbox   #
tie *STDOUT, 'Tk::Text', $text -> Subwidget( 'scrolled' );

$text -> insert( 'end', "The size of carma_results folder is: $wd_size\n", );

# If OS is *nix/unix-like insert a     #
# line informing the user of the prog  #
# selected for .ps viewing             #
if ( $^O eq 'linux' ) {

	if ( $ps_viewer ) {

		$text -> insert( 'end', "\nThe program selected for .ps viewing is \"$ps_viewer\"\n", 'info' );
	}

	if ( $pdb_viewer ) {

		$text -> insert( 'end', "\nThe program selected for .pdb viewing is \"$pdb_viewer\"\n", 'info' );
	}
}

$text -> insert( 'end', "\nSELECT A TASK FROM THE LEFT PANEL\n" );

###################################################################################################
###   Active file frame                                                                         ###
###################################################################################################

# Draw the seventh frame(active files) #
# on top of the first one immediately  #
# after the fifth frame is drawn       #
my $f6 = $f0 -> Frame() -> pack( -after => $f1,
								-side => 'bottom',
								-fill => 'x',
								-expand => 1, );

# Create the labels displaying the     #
# active .psf & .dcd files and update  #
# the mainwindow to include them       #
our $active_psf_label = $f6 -> Label( -text => "Active .psf: $psf_file", )
								  -> pack( -side => 'left', );
our $active_dcd_label = $f6 -> Label( -text => "Active .dcd: $dcd_file", )
								  -> pack( -side => 'right', );

$mw -> update();

# Get the resolution of the screen     #
# and position the mainwindow centered #
# and every other window to it's right #
my $x_position = int ( ( $mw -> screenwidth / 2 ) - ( $mw -> width / 2 ) );
my $y_position = int ( ( ( $mw -> screenheight - 80 ) / 2 ) - ( $mw -> height / 2 ) );

my $mw_position = "+" . $x_position . "+" . $y_position;
my $toplevel_position = "+" . ( $x_position + 150 ) . "+" . ( $y_position + 100 );

$mw -> geometry ("$mw_position");
# This is due to a windows-exlusive    #
# bug that forces the window to the    #
# background                           #
$mw -> focusForce if ( $^O ne 'linux' );

###################################################################################################
###   End of main program                                                                       ###
###################################################################################################

MainLoop;

###################################################################################################
###   Open files from GUI                                                                       ###
###################################################################################################

sub open_file {

	# Depending on the argument that this  #
	# subroutine is passed, the $filetypes #
	# variable will be set to psf or dcd   #
	# restricting the files viewed with    #
	# the getOpenMethod to the extension   #
	# currently in $filetypes              #

	if ( $^O eq 'linux' ) {

		if ( $_[0] eq 'psf' || $_[0] eq 'sort' ) {

			$filetypes = [ ['PSF Files', '.psf'] ];
		}
		elsif ( $_[0] eq 'dcd' ) {

			$filetypes = [ ['DCD Trajectory Files', '.dcd'] ];
		}
	}
	# Again, due to another bug on windows #
	# the variable needs to be defined     #
	# differently                          #
	else {

		if ( $_[0] eq 'psf' || $_[0] eq 'sort' ) {

			$filetypes = [['PSF FIles',  '.psf'], ['PSF FIles',  '.psf']];
		}
		elsif ( $_[0] eq 'dcd' ) {

			$filetypes = [['DCD Trajectory Files', '.dcd'], ['DCD Trajectory Files', '.dcd']];
		}
	}

	my $file = $mw -> getOpenFile( -filetypes => $filetypes, -initialdir => getcwd, );
	# If the file selected through the     #
	# getOpen method is a .psf file        #
	if ( $file =~ /\w*\.psf/ ) {

		if ( $^O eq 'linux' ) {

			# If on *nix invoke the abs_path       #
			# subroutine and store it's result in  #
			# a scalar. This is nessecary because  #
			# normally relative paths will be used #
			# rendering the data in $psf_file      #
			# obsolete every time the working      #
			# directory is changed                 #
			$psf_file = abs_path ( $file );
		}
		else {

			# else substitute the '/' for '\' in   #
			# $file as windows uses a backward     #
			# slash & the getOpen method returns   #
			# the absolute path to the file unix-  #
			# style                                #
			$file =~ s/\//\\/g;
			$psf_file = $file;
		}
		our $have_psf = 1;
	}
	# Do the same for .dcd files and add a #
	# scalar which contains the the name   #
	# of the dcd file                      #
	elsif ( $file =~ /.*\/(\w*)\.dcd/ ) {

		if ( $^O eq 'linux' ) {

			$dcd_file = abs_path ( $file );
			$dcd_name = $1;
		}
		else {

			$dcd_name = $1;
			$file =~ s/\//\\/g;
			$dcd_file = $file;
		}
		our $have_dcd = 1;
	}
	# If the file selected is not a psf or #
	# a dcd, then display a window with a  #
	# warning                              #
	else {

		my $top1 = $mw -> Toplevel( -title => 'Error Message', );
		$top1 -> Label( -text => "Only .psf and .dcd files acceptable", )
						-> pack( -side => 'left',);
		$top1 -> Button ( -text => 'OK',
						  -command => [ $top1 => 'destroy' ], )
						  -> pack( -side => 'right', );
	}

	if ( our $have_psf && our $have_dcd ) {

		&parser;

		$have_psf = 0;
		$have_dcd = 0;
	}
}

###################################################################################################
###   Run carma with the selected parameters                                                    ###
###################################################################################################

sub carma {

	# Set the variable used for reporting  #
	# success to the rest of the program   #
	# to zero and substitute any multiple  #
	# spaces in the $flag scalar with a    #
	# single space                         #

	our $all_done = 0;
	our $flag =~ s/[\s]\s+/ /g;

	our $remember_psf;
	our $remember_dcd;
	our $dcd_count;

	if ( $^O ne 'linux' ) {

		$text -> insert( 'end', " Running carma with the flag :\n", 'valid' );
		$text -> insert( 'end', "$flag\n", 'info' );
		$text -> see( 'end', );
		$mw -> update;

		if ( $_[0] && $_[0] eq 'auto' ) {

			`carma.exe $flag > carma.out.copy`;
		}

		# If the subroutine was called from    #
		# the fitting subroutine then perform  #
		# the carma run only with the dcd file #
		if ( $_[0] && $_[0] eq 'sort' ) {

			`carma.exe $flag \"$dcd_name.dcd\" > carma.out.copy`;
		}

		# Else if the user has opted to use    #
		# selected residues for calculations   #
		elsif ( $have_custom_psf ) {

			# and the calculations are to be made  #
			# using a fitted .dcd then run carma   #
			# with the 'selected_residues.psf'     #
			# file, which must be located in the   #
			# working directory, and the fitted    #
			# .dcd file                            #
			if ( $dcd_count >= 0 && $_[0] ne "fit" ) {

				`carma.exe $flag \"selected_residues.psf\" \"carma_fitted_$dcd_count.dcd\" > carma.out.copy`;
				$remember_psf = "selected_residues.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "carma_fitted_$dcd_count.dcd" if ( $_[0] && $_[0] eq "pca" );
			}

			# otherwise run it with the same .psf  #
			# and the original .dcd                #
			else {

				`carma.exe $flag \"selected_residues.psf\" \"$dcd_name.dcd\" > carma.out.copy`;
				$remember_psf = "selected_residues.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "$dcd_name.dcd" if ( $_[0] && $_[0] eq "pca" );
			}
		}
		# Else if none of the above contitions #
		# are true                             #
		else {

			# and the calculations are to be made  #
			# with a fitted .dcd then run carma    #
			# with the fitted .dcd and .psf files  #
			if ( $dcd_count >= 0 && $_[0] ne "fit" ) {

				`carma.exe $flag \"carma_fitted_$dcd_count.psf\" \"carma_fitted_$dcd_count.dcd\" > carma.out.copy`;
				$remember_psf = "carma_fitted_$dcd_count.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "carma_fitted_$dcd_count.dcd" if ( $_[0] && $_[0] eq "pca" );
			}
			# otherwise run it with the original   #
			# .psf and .dcd files                  #
			else {

				`carma.exe $flag \"psf_file.psf\" \"$dcd_name.dcd\" > carma.out.copy`;
				$remember_psf = "psf_file.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "$dcd_name.dcd" if ( $_[0] && $_[0] eq "pca" );
			}
		}
	}
	# repeat for *nix OS but run carma     #
	# through 'xterm' so that the user can #
	# monitor the program in real time     #
	else {

		$text -> insert( 'end', "Running carma with the flag :\n", 'valid' );
		$text -> insert( 'end', "$flag\n", 'info' );
		$text -> see( 'end', );
		$mw -> update;

		if ( $_[0] && $_[0] eq 'auto' ) {

			`xterm -geometry 80x25+800+200 -e "carma $flag | tee carma.out.copy"`;
		}
		elsif ( $_[0] && $_[0] eq 'sort' ) {

			`xterm -geometry 80x25+800+200 -e "carma $flag $remember_dcd | tee carma.out.copy"`;
		}
		elsif ( $have_custom_psf ) {

			if ( $dcd_count >= 0 && $_[0] ne "fit" ) {

				`xterm -geometry 80x25+800+200 -e "carma $flag selected_residues.psf carma_fitted_$dcd_count.dcd | tee carma.out.copy"`;
				$remember_psf = "selected_residues.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "carma_fitted_$dcd_count.dcd" if ( $_[0] && $_[0] eq "pca" );
			}
			else {

				`xterm -geometry 80x25+800+200 -e "carma $flag selected_residues.psf $dcd_file | tee carma.out.copy"`;
				$remember_psf = "selected_residues.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "$dcd_file" if ( $_[0] && $_[0] eq "pca" );
			}
		}
		else {

			if ( $dcd_count >= 0 && $_[0] ne "fit" ) {

				`xterm -geometry 80x25+800+200 -e "carma $flag carma_fitted_$dcd_count.psf carma_fitted_$dcd_count.dcd | tee carma.out.copy"`;
				$remember_psf = "carma_fitted_$dcd_count.psf" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "carma_fitted_$dcd_count.dcd" if ( $_[0] && $_[0] eq "pca" );
			}
			else {

				`xterm -geometry 80x25+200+200 -e "carma $flag $psf_file $dcd_file | tee carma.out.copy"`;
				$remember_psf = "$psf_file" if ( $_[0] && $_[0] eq "pca" );
				$remember_dcd = "$dcd_file" if ( $_[0] && $_[0] eq "pca" );
			}
		}
	}

	# When the run is completed open the   #
	# file 'carma.out.copy' in the CWD and #
	# parse through it one line at a time  #
	# searching for the pattern 'All done' #
    open TEMP_OUT, "carma.out.copy" || die "Cannot open carma.out.copy for reading: $!\n";
    while ( <TEMP_OUT> ) {

		# If a match is found set the value of #
		# $all_done to 1                       #
		if ( $_ !~ /Abort|boo|problem/i ) {

			$all_done = 1;
		}
	}

	close TEMP_OUT;

	$flag = 0;
	#~ $seg_id_flag = '';
	$index_seg_id_flag = '';
}

###################################################################################################
###   Parse the .psf file to extract info for the protein(s)                                    ###
###################################################################################################

sub parser {

	open ( PSF_FILE, $psf_file ) || die "Cannot open $psf_file for reading: $!\n";

	# Extract the number of atoms found    #
	# in the .psf file                     #
	our $num_atoms = 0;
	while ( <PSF_FILE> ) {

		if ( /(\d*)\s\!NATOM/ ) {

			$num_atoms = $1;
			last;
		}
	}

	my $i = 0;
	my $j = 0;
	my $k = 0;

	my @atom_types;
	my @chain_ids;
	our %num_residues;

	# Continue parsing through the .psf    #
	# file storing the various atmids and  #
	# segids as well as the number of      #
	# residues in each chain               #
	while ( <PSF_FILE> ) {

		if ( /\d+\s*\w+\s*\d+\s*\w+\s*(\w+)/ && $i < $num_atoms ) {

			$atom_types[$i] = $1;
			$i++;
		}
		if ( /\d+\s*(\w+)/ && $j < $num_atoms ) {

			$chain_ids[$j] = $1;
			$j++;
		}
		if ( /\d+\s*([A-Z])\s*(\d+)\s*\w+\s*\w+/ ) {

			$num_residues{$1} = $2;
		}
	}

	close ( PSF_FILE );

	# Substitute every proton atmid for H  #
	foreach ( @atom_types ) {

		if ( $_ =~ /^H.*/ ) {

			$_ =~ s/^H.*/H/g;
		}
	}

	# Sort the atmids - segids and remove  #
	# any and all multiple entries         #
	my @sorted_atom_types = sort ( @atom_types );
	our @unique_atom_types = uniq ( @sorted_atom_types );

	my @sorted_chain_ids = sort ( @chain_ids );
	our @unique_chain_ids = uniq ( @sorted_chain_ids);

	# Use carma to check the validity by   #
	# parsing the output of the following  #
	# carma run searching for the presence #
	# of the word 'Abort'                  #
	my $valid_psf_dcd_pair = '';
	if ( $^O eq 'linux' ) {

		$valid_psf_dcd_pair = `carma -v -fit -last 2 $psf_file $dcd_file`;
	}
	else {

		$valid_psf_dcd_pair = `carma.exe -v -fit -last 2 \"$psf_file\" \"$dcd_file\"`;
	}

	unlink ( "carma.fit-rms.dat", "carma.fitted.dcd", ) or print "yo";

	# If found create a help message or    #
	# a window prompting the user to retry #
	if ( $valid_psf_dcd_pair =~ /Abort./i ) {

		if ( $run_from_terminal ) {

			die "\nNumber of atoms in PSF and DCD do not match.\n\n";
		}
		else {

			$gui -> packForget;
			my $response = $gui -> messageBox( -message => "Number of atoms in PSF and DCD do not match.\nWould you like to retry?",
											   -type => 'yesno',
											   -icon => 'warning', );

			if ( $response eq "Yes" ) {

				$gui -> pack;
				$dcd_button -> configure( -state => 'normal', );
				$psf_button -> configure( -state => 'normal', );
			}
			else {

				exit(1);
			}
		}
	}
	elsif ( @unique_chain_ids >= 10 ) {

		if ( $run_from_terminal ) {

			die "\nIt seems that the .psf file lacks chain ids. Please fix and retry.\n\n";
		}
		else {

			$mw -> messageBox ( -message => "It seems that the .psf file lacks chain ids. Please fix and retry.",
								-type => 'ok',
								-icon => 'warning', );
			$mw -> destroy;
			die($!);
		}
	}

	# If not found proceed parsing the dcd #
	# header                               #
	else {

		&dcd_header_parser;
	}
}

###################################################################################################
###   Parse the STDOUT of carma to extract the number of frames in the header of the .dcd file  ###
###################################################################################################

sub dcd_header_parser {

	if ( $^O eq 'linux' ) {

		`carma -v -fit -first 1 -last 2 $psf_file $dcd_file > carma.out`;
	}
	else {

		`carma.exe -v -fit -first 1 -last 2 $psf_file $dcd_file > carma.out`;
	}

	# Extract the number of frames found   #
	# in the .dcd header                   #
	open OUTPUT, '<', "carma.out" || die "Cannot open carma.out for reading: $!";
	while ( <OUTPUT> ) {

		if ( /Number of coordinate sets is (\d+)/ ) {

			$header = $1;
		}
	}

	close (OUTPUT);
	unlink ( "carma.out", );

	# If the number or frames is greater   #
	# than 3k set the value of $rmsd_step  #
	# to $header/3000 rounded up to the    #
	# nearest integer, otherwise set it to #
	# 1                                    #
	if ( $header <= 3000 ) {

		$rmsd_step = 1;
	}
	elsif ( $header > 3000 ) {

		$rmsd_step = int ( ( $header / 3000 ) + 0.5 );
	}

	# At this point every check has been   #
	# succesful and unless the program was #
	# run from the terminal, the container #
	# frame is drawn and at the same time  #
	# the window for file selection is     #
	# withdrawn                            #
	unless ( $run_from_terminal ) {

		$gui -> packForget();
		$f0 -> pack( -side => 'top', -fill => 'both', -expand => 1, );
		$f0 -> update;
		$run_from_terminal = 0;
	}

	$have_files = 1;
}

###################################################################################################
###   Draw the window containing every atmid in the PSF file                                    ###
###################################################################################################

sub raise_custom_window {

	# The same format is used throughout   #
	# the program for the subroutines that #
	# are used in order to cover the many  #
	# different keywords used by carma so  #
	# they will be described in detail in  #
	# the comments of this subroutine and  #
	# are valid for every subroutine which #
	# follows                              #

	# First, the variables, arrays, hashes #
	# are imported ( when necessary ) and  #
	# initialised                          #
	my $x = 1;
	my $y = 1;

	our $custom_id_flag = '';
	our $custom_selection = '';

	our @custom_atom_ids;

	# Second, if the toplevel window does  #
	# not exist, it is created and it's    #
	# elements are defined                 #
	if ( !Exists( my $top_custom ) ) {

		# The toplevel is drawn, titled and    #
		# positioned. The 'X' button in the    #
		# upper right ( or left depending on   #
		# your window manager ) corner doesn't #
		# destroy the window but withdraws it  #
		my $top_custom = $mw -> Toplevel();
		$top_custom -> geometry("$toplevel_position");
		$top_custom -> protocol( 'WM_DELETE_WINDOW' => sub { $top_custom -> withdraw });
		$top_custom -> title( "Custom selection" );

		my $frame_custom1 = $top_custom -> Frame() -> pack( -side => 'bottom', );
		my $frame_custom2 = $top_custom -> Frame() -> pack( -side => 'top', );

		$frame_custom1 -> Button( -text => 'Submit',
								  -command => sub {

								   $top_custom -> withdraw;

								   # Foreach active element of the array  #
								   # @custom_atom_ids add its atmid to a  #
								   # scalar and use it for the flag       #
								   foreach ( @custom_atom_ids ) {

									   if ( defined ) {

										   if ( /(\w+)/ ) {

												$custom_id_flag = $custom_id_flag . " -atmid " . $1;
												$custom_selection = 1;
												$atm_id_flag = '';
											}
									   }
								   }
							   }, )
							   -> pack( -side => 'right', );

		$frame_custom1 -> Button( -text => 'Return',
								  -command => [ $top_custom => 'withdraw' ], )
								  -> pack(-side => 'left', );

		# For every atmid draw a checkbutton   #
		# and name it after itself. If it is   #
		# active store the atmid in the array  #
		# @custom_atom_ids                     #
		our @unique_atom_types;
		for my $i ( 0 .. $#unique_atom_types ) {

			$frame_custom2 -> Checkbutton( -text => $unique_atom_types[$i],
										   -offvalue => '',
										   -onvalue => $unique_atom_types[$i],
										   -variable => \$custom_atom_ids[$i], )
										   -> grid( -row => "$x", -column => "$y", -sticky => 'w', );

			$x++;
			if ( $x == 5 ) {

				$y++;
				$x = 1;
			}
		}
	}

	# Finally, if the window has already   #
	# been created it is brought in the    #
	# foreground                           #
	else {

		$custom_id_flag = '';
		$atm_id_flag = '';
		$top_custom -> deiconify;
		$top_custom -> raise;
	}
}

###################################################################################################
###   Draw the window for the RMSD matrix calculation                                           ###
###################################################################################################

sub rmsd_window {

	my $rmsd_first = '';
	my $rmsd_first_flag = '';
	my $rmsd_last = '';
	my $rmsd_last_flag = '';
	my $rmsd_step_flag = '';
	my $rmsd_min = '';
	my $rmsd_min_flag = '';
	my $rmsd_max = '';
	my $rmsd_max_flag = '';
	my $rmsd_reverse = '';
	my $rmsd_top;

	our $rmsd_step;

	if ( !Exists( $rmsd_top ) ) {

		$rmsd_top = $mw -> Toplevel( -title => 'RMSD matrix' );
		$rmsd_top -> geometry("$toplevel_position");

		my $frame_rmsd1 = $rmsd_top -> Frame() -> pack();

		# Create entry boxes for user input    #
		$frame_rmsd1 -> Label( -text => 'First: ', )
							   -> grid( -row => 1, -column => 1, );
		$frame_rmsd1 -> Entry( -textvariable => \$rmsd_first, )
							   -> grid( -row => 1, -column => 2, );
		$frame_rmsd1 -> Label( -text => 'Last: ', )
							   -> grid( -row => 2, -column => 1, );
		$frame_rmsd1 -> Entry( -textvariable => \$rmsd_last, )
							   -> grid( -row => 2, -column => 2, );
		$frame_rmsd1 -> Label( -text => 'Step: ', )
							   -> grid( -row => 3, -column => 1, );
		$frame_rmsd1 -> Entry( -textvariable => \$rmsd_step, )
							   -> grid( -row => 3, -column => 2, );

		$frame_rmsd1 -> Label( -text => 'Min: ', )
							   -> grid( -row => 1, -column => 3, );
		$frame_rmsd1 -> Entry( -textvariable => \$rmsd_min, )
							   -> grid( -row => 1, -column => 4, );
		$frame_rmsd1 -> Label( -text => 'Max: ', )
							   -> grid( -row => 2, -column => 3, );
		$frame_rmsd1 -> Entry( -textvariable => \$rmsd_max, )
							   -> grid( -row => 2, -column => 4, );

		$frame_rmsd1 -> Checkbutton( -text => 'Reverse',
									 -variable => \$rmsd_reverse,
									 -offvalue => '',
									 -onvalue => " -reverse", )
									 -> grid( -row => 3, -column => 3, );

		my $frame_rmsd2 = $rmsd_top -> Frame() -> pack();

		# For every variable used for input    #
		# that is active create a flag and add #
		# it to the flag used to run carma     #
		$frame_rmsd2 -> Button( -text => 'Run',
								-command => sub {

			if ( $rmsd_first ) {

				$rmsd_first_flag = " -first $rmsd_first";
			}
			else {

				$rmsd_first_flag = '';
			}

			if ( $rmsd_last ) {

				$rmsd_last_flag = " -last $rmsd_last";
			}
			else {

				$rmsd_last_flag = '';
			}

			if ( $rmsd_step ) {

				$rmsd_step_flag = " -step $rmsd_step";
			}
			else {

				$rmsd_step_flag = '';
			}

			if ( $rmsd_min ) {

				$rmsd_min_flag = " -min $rmsd_min";
			}
			else {

				$rmsd_min_flag = '';
			}

			if ( $rmsd_max ) {

				$rmsd_max_flag = " -max $rmsd_max";
			}
			else {

				$rmsd_max_flag = '';
			}

			$rmsd_top -> destroy();
			$mw -> update;

			# If a segid has been specified    #
			# add it to the flag as well       #

			$seg_id_flag = '' if $seg_id_flag;

			foreach ( @seg_ids ) {

				if ( defined ) {

					$seg_id_flag = $seg_id_flag . $_;
				}
			}

			if ( $seg_id_flag ) {

				$flag = " -v -w -cross $rmsd_first_flag $rmsd_last_flag $rmsd_step_flag $rmsd_min_flag $rmsd_max_flag $rmsd_reverse $seg_id_flag $atm_id_flag $custom_id_flag $res_id_flag";
			}
			else {

				$flag = " -v -w -cross $rmsd_first_flag $rmsd_last_flag $rmsd_step_flag $rmsd_min_flag $rmsd_max_flag $rmsd_reverse $atm_id_flag $custom_id_flag $res_id_flag";
			}
			&create_dir;

			$text -> insert( 'end', "\nNow calculating RMSD matrix. ", 'valid', );
			$text -> see( 'end', );
			$mw -> update;

			&carma;
			if ( $^O ne 'linux' ) {

				# If the carma run was succesful make  #
				# a .ps plot of the produced matrix    #
				# while capturing the limits used for  #
				# the colouring                        #
				if ( $all_done ) {

					if ( `carma.exe -colour - < \"carma.RMSD.matrix\"` =~ /(-?\d*)\.(\d*) to (-?\d*)\.(\d*)/ ) {

						$text -> insert( 'end', "\nCalculation finished. Plotted .ps image from $1.$2 to $3.$4\n", 'valid' );
						$text -> insert( 'end', "Use \"View Images\"\n", 'valid' );
						$text -> see( 'end', );
						$image_menu -> configure( -state => 'normal', );
					}
				}
				# Else report it with a help message   #
				else {

					$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
					$text -> insert( 'end', getcwd . "\n", 'info', );
					$text -> see( 'end', );
				}
			}
			else {

				if ( $all_done ) {

					if ( `carma -colour - < carma.RMSD.matrix` =~ /(-?\d*)\.(\d*) to (-?\d*)\.(\d*)/ ) {

						$text -> insert( 'end', "\nCalculation finished. Plotted .ps image from $1.$2 to $3.$4\n", 'valid' );
						$text -> insert( 'end', "Use \"View Images\"\n", 'valid' );
						$text -> see( 'end', );
						$image_menu -> configure( -state => 'normal', );
					}
				}
				else {

					$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
					$text -> insert( 'end', getcwd . "\n", 'info', );
					$text -> see( 'end', );
				}
			}
			}, )
			-> grid( -row => 2, -column => 2, );

		$frame_rmsd2 -> Button( -text => 'Return',
							    -command => [ $rmsd_top => 'withdraw' ], )
							    -> grid( -row => 2, -column => 1, );

	}
	else {

		$rmsd_top -> deiconify;
		$rmsd_top -> raise;
	}

}

###################################################################################################
###   Draw the window for the dPCA calculation                                                  ###
###################################################################################################

sub dpca_window {

	my $dpca_eigenvectors = '';
	my $dpca_combinations = '';
	my $dpca_temp = '';
	my $dpca_cutoff = '';
	my $dpca_dgwidth = '';
	my $dpca_dgwidth_num = '';
	my $dpca_3d = '';
	my $chi1 = '';
	my $dpca_top;

	our $res_id_flag;

	if ( !Exists( $dpca_top ) ) {

		unless ( $dpca_temp ) {

			$dpca_temp = 298;
			$dpca_eigenvectors = 5;
			$dpca_combinations = 3;
		}

		$dpca_top = $mw -> Toplevel( -title => 'Dihedral PCA ' );
		$dpca_top -> geometry("$toplevel_position");

		$dpca_frame = $dpca_top -> Frame( -borderwidth => 3,
										  -relief => 'groove', );

		$dpca_frame -> Label( -text => 'Temperature(K): ',)
							  -> grid( -row => 1, -column => 1, -sticky => 'w', );
		$dpca_frame -> Entry( -textvariable => \$dpca_temp,)
							  -> grid( -row => 1, -column => 3, );
		$dpca_frame -> Label( -text => 'Total eigenvectors: ',
							  -anchor => 'e',)
							  -> grid( -row => 2, -column => 1, -sticky => 'w', );
		$dpca_frame -> Entry( -textvariable => \$dpca_eigenvectors,)
							  -> grid( -row => 2, -column => 3, );
		$dpca_frame -> Label( -text => 'Combinations: ',
							  -anchor => 'e',)
							  -> grid( -row => 3, -column => 1, -sticky => 'w', );
		$dpca_frame -> Entry( -textvariable => \$dpca_combinations,)
							  -> grid( -row => 3, -column => 3, );
		$dpca_frame -> Label( -text => 'Sigma cutoff(optional): ',
							  -anchor => 'e',)
							  -> grid( -row => 4, -column => 1, -sticky => 'w', );
		$dpca_frame -> Entry( -textvariable => \$dpca_cutoff,)
							  -> grid( -row => 4, -column => 3, );

		$dpca_frame -> Checkbutton( -text => 'DG width: ',
									-anchor => 'e',
									-variable => \$dpca_dgwidth,
									-onvalue => " -dgwidth",
									-offvalue => '', )
									-> grid( -row => 5, -column => 1, -sticky => 'w', );
		$dpca_frame -> Entry( -textvariable => \$dpca_dgwidth_num,)
							  -> grid( -row => 5, -column => 3, );

		$dpca_frame -> Label( -text => "For dPCA your atom type selection will be ignored.", )
							  -> grid( -row => 6, -column => 2, );

		$dpca_frame ->Button( -text => 'Return',
							  -command => sub {

								$dpca_top -> withdraw;
								my $count = 0;
								}, )
						      -> grid ( -row => 7, -column => 1, );

		$dpca_run_button = $dpca_frame ->Button( -text => 'Run',
												 -command => sub {

								$dpca_top -> withdraw;

								$seg_id_flag = '' if $seg_id_flag;

								foreach ( @seg_ids ) {

									if ( defined ( $_ ) ) {

										$seg_id_flag = $seg_id_flag . $_;
									}
								}

								if ( $seg_id_flag ) {

									$flag = " -v -w -col $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag $seg_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
								}
								else {

								$flag = " -v -w -col $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
								}
								&create_dir;

								$text -> insert( 'end', "\nNow performing dPCA. ", 'valid', );
								$text -> see( 'end', );
								$mw -> update;

								&carma ( "pca" );
								&auto_window ( 'dpca' ) if ( $dpca_auto_entry -> cget( -state, ) eq 'normal' );
								if ( $all_done ) {

									$text -> insert( 'end', "\nCalculation finished. Use \"View Images\"\n", 'valid' );
									$text -> see( 'end', );
									$image_menu -> configure( -state => 'normal', );
									$sort_menu -> configure( -state => 'normal', );
									$all_done = '';
								}
								else {

									$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
									$text -> insert( 'end', getcwd . "\n", 'info', );
									$text -> see( 'end', );
								}
								}, )
								-> grid( -row => 7, -column => 3, );

		if ( $active_run_buttons ) {

			$dpca_run_button -> configure( -state => 'normal', );
		}
		else {

			$dpca_run_button -> configure( -state => 'disabled', );
		}

		$dpca_frame_1 = $dpca_top -> Frame() -> pack( -fill => 'x', );
		my $dpca_frame_2 = $dpca_top -> Frame() -> pack( -fill => 'x', );

		&checkbuttons ( $dpca_frame_1 );
		&otherbuttons ( $dpca_frame_2 );

		my $dpca_frame_3 = $dpca_top -> Frame()-> pack( -side => 'top', -expand => 1, -fill => 'x', );
		my $dpca_frame_4 = $dpca_top -> Frame()-> pack( -side => 'top', -expand => 1, -fill => 'x', );

		$dpca_frame -> pack( -side => 'top', -expand => 1, -fill => 'both', );

		$dpca_frame_3 -> Label( -text => 'Various Options' )
								-> grid( -row => 1, -column => 1, );

		$dpca_auto_entry = $dpca_frame_4 -> Entry( -textvariable => \$dpca_auto_entry_num,
												   -state => 'disabled', )
												   -> grid( -row => 2, -column => 2, );

		$dpca_frame_4 -> Label( -text => 'clusters', ) -> grid( -row => 2, -column => 3, );

		$dpca_frame_4 -> Checkbutton( -text => 'Automatically isolate max: ',
									  -command => sub {

										  if ( $dpca_auto_entry -> cget( -state, ) eq 'disabled' ) {

											  $dpca_auto_entry -> configure( -state => 'normal', );
										  }
										  else {

											  $dpca_auto_entry -> delete( 0, 'end', );
											  $dpca_auto_entry -> configure( -state => 'disabled', );
										  }
										  }, )
									  -> grid( -row => 2, -column => 1, -sticky => 'w', );
		$dpca_frame_4 -> Checkbutton( -text => 'Create 3D landscapes',
									  -variable => \$dpca_3d,
									  -offvalue => '',
									  -onvalue => " -3d", )
									  -> grid( -row => 3, -column => 1, -sticky => 'w', );
		$dpca_frame_4 -> Checkbutton( -text => 'Chi1',
									  -variable => \$chi1,
									  -offvalue => '',
									  -onvalue => " -chi1", )
									  -> grid( -row => 4, -column => 1, -sticky => 'w', );
	}
	else {

		$dpca_top -> deiconify;
		$dpca_top -> raise;
	}

}

###################################################################################################
###   Draw the window for the cPCA calculation                                                  ###
###################################################################################################

sub cpca_window {

	my $cpca_eigenvectors = '';
	my $cpca_combinations = '';
	my $cpca_temp = '';
	my $cpca_cutoff = '';
	my $cpca_dgwidth = '';
	my $cpca_dgwidth_num = '';
	my $cpca_3d = '';
	my $chi1 = '';
	my $cpca_mass = '';
	my $cpca_use = '';
	my $cpca_top;

	if ( !Exists( $cpca_top ) ) {

		unless ( $cpca_temp ) {

			$cpca_temp = 298;
			$cpca_eigenvectors = 5;
			$cpca_combinations = 3;
		}

		$cpca_top = $mw -> Toplevel( -title => 'Cartesian PCA ' );
		$cpca_top -> geometry("$toplevel_position");

		$cpca_frame = $cpca_top -> Frame( -borderwidth => 3,
										  -relief => 'groove', );

		$cpca_frame -> Label( -text => 'Temperature(K): ',)
							  -> grid( -row => 1, -column => 1, -sticky => 'w', );
		$cpca_frame -> Entry( -textvariable => \$cpca_temp,)
							  -> grid( -row => 1, -column => 3, );

		$cpca_frame -> Label( -text => 'Total eigenvectors: ',
							  -anchor => 'e',)
							  -> grid( -row => 2, -column => 1, -sticky => 'w', );
		$cpca_frame -> Entry( -textvariable => \$cpca_eigenvectors,)
							  -> grid( -row => 2, -column => 3, );
		$cpca_frame -> Label( -text => 'Combinations: ',
							  -anchor => 'e',)
							  -> grid( -row => 3, -column => 1, -sticky => 'w', );
		$cpca_frame -> Entry( -textvariable => \$cpca_combinations,)
							  -> grid( -row => 3, -column => 3, );
		$cpca_frame -> Label( -text => 'Sigma cutoff(optional): ',
							  -anchor => 'e',)
							  -> grid( -row => 4, -column => 1, -sticky => 'w', );
		$cpca_frame -> Entry( -textvariable => \$cpca_cutoff,)
							  -> grid( -row => 4, -column => 3, );
		$cpca_frame -> Checkbutton( -text => 'DG width: ',
									-anchor => 'e',
									-variable => \$cpca_dgwidth,
									-onvalue => " -dgwidth",
									-offvalue => '', )
									-> grid(-row=>5,-column=>1, -sticky => 'w', );
		$cpca_frame -> Entry( -textvariable => \$cpca_dgwidth_num,)
							  -> grid( -row => 5, -column => 3, );

		$cpca_frame ->Button( -text => 'Return',
							  -command => sub {

							  $cpca_top -> withdraw;
							  our $count = 0;
							  }, )
							 -> grid( -row => 7, -column => 1 );

		$cpca_frame ->Button( -text => 'Run',
							  -command => sub {

								$cpca_top -> withdraw;

								$seg_id_flag = '' if $seg_id_flag;

								foreach ( @seg_ids ) {

									if ( defined ( $_ ) ) {

										$seg_id_flag = $seg_id_flag . $_;
									}
								}

								if ( $seg_id_flag ) {

									$flag = " -v -w -col -cov $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $seg_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
								}
								else {

									$flag = " -v -w -col -cov $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
								}
								&create_dir;

								$text -> insert( 'end', "\nNow performing cPCA. ", 'valid', );
								$text -> see( 'end', );
								$mw -> update;

								&carma ( "pca" );
								&auto_window ( 'cpca' ) if $cpca_auto_entry -> cget( -state, ) eq 'normal';

								if ( $all_done ) {

									$text -> insert( 'end', "\nCalculation finished. Use \"View Images\"\n", 'valid' );
									$text -> see( 'end', );
									$image_menu -> configure( -state => 'normal', );
									$sort_menu -> configure( -state => 'normal', );
									$all_done = '';
								}
								else {

									$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
									$text -> insert( 'end', getcwd . "\n", 'info', );
									$text -> see( 'end', );
								}
								}, )
								->grid( -row => 7, -column => 3 );

		$cpca_frame_1 = $cpca_top -> Frame()->pack( -fill => 'x', );
		my $cpca_frame_2 = $cpca_top -> Frame()-> pack( -fill => 'x', );
		my $cpca_frame_3 = $cpca_top -> Frame()-> pack( -fill => 'x', );
		my $cpca_frame_5 = $cpca_top -> Frame()-> pack( -side => 'top',
														-expand => 1,
														-fill => 'x', );
		my $cpca_frame_4 = $cpca_top -> Frame()-> pack( -side => 'top',
														-expand => 1,
														-fill => 'x', );

		&radiobuttons ( $cpca_frame_1 );
		&checkbuttons ( $cpca_frame_2 );
		&otherbuttons ( $cpca_frame_3 );

		$cpca_frame -> pack( -side => 'top', -expand => 1, -fill => 'both', );

		$cpca_frame_5 -> Label( -text => 'Various Options' ) -> pack;

		$cpca_auto_entry = $cpca_frame_4 -> Entry( -textvariable => \$cpca_auto_entry_num,
												   -state => 'disabled', )
												   -> grid( -row => 2, -column => 2, );

		$cpca_frame_4 -> Label( -text => 'clusters', ) -> grid( -row => 2, -column => 3, );

		$cpca_frame_4 -> Checkbutton( -text => 'Automatically isolate max: ',
									  -command => sub {

										  if ( $cpca_auto_entry -> cget( -state, ) eq 'disabled' ) {

											  $cpca_auto_entry -> configure( -state => 'normal', );
										  }
										  else {

											  $cpca_auto_entry -> delete( 0, 'end', );
											  $cpca_auto_entry -> configure( -state => 'disabled', );
										  }
										  }, )
									  -> grid( -row => 2, -column => 1, -sticky => 'w', );

		$cpca_frame_4 -> Checkbutton( -text => 'Mass',
									  -variable => \$cpca_mass,
									  -offvalue => '',
									  -onvalue => " -mass", )
									  -> grid( -row => 3, -column => 1, -sticky => 'w', );
		$cpca_frame_4 -> Checkbutton( -text => 'Create 3D landscapes',
									  -variable => \$cpca_3d,
									  -offvalue => '',
									  -onvalue => " -3d", )
									  -> grid( -row => 4, -column => 1, -sticky => 'w', );
		$cpca_frame_4 -> Checkbutton( -text => 'Use previously calculated eigenvalues',
									  -variable => \$cpca_use,
									  -offvalue => '',
									  -onvalue => " -use", )
									  -> grid( -row => 5, -column => 1, -sticky => 'w', );
	}
	else {

		$cpca_top -> deiconify;
		$cpca_top -> raise;
	}
}

###################################################################################################
###   Automated cluster analysis                                                                ###
###################################################################################################

sub auto_window {

	my $clusters;
	my @clusters;

	my $fit_check = 0;
	my $super_check = 0;

	&create_dir;

	open CLUSTERS, "carma.clusters.dat" || die "Cannot open carma.clusters.dat for reading\n";

	my $i = 0;
	while ( <CLUSTERS> ) {

		if ( /(\s*\d+\s*)(\d*)(.*)/ ) {

			$clusters[$i] = $2;
			$i++;
		}
	}
	close CLUSTERS;

	@clusters = uniq ( @clusters );
	$clusters = @clusters;

	if ( $_[0] eq 'cpca' && $clusters > $cpca_auto_entry_num ) {

		$clusters = $cpca_auto_entry_num;
	}
	elsif ( $_[0] eq 'dpca' && $clusters > $dpca_auto_entry_num ) {

		$clusters = $dpca_auto_entry_num;
	}

	for ( $i = 1 ; $i <= $clusters ; $i++ ) {

		open CLUSTERS, "carma.clusters.dat" || die "Cannot open carma.clusters.dat for reading: $!\n";

		my $file = "C_0$i.dat";
		open OUT, '>', $file || die "Cannot open $file for writing\n: $!";

		while ( <CLUSTERS> ) {

			if ( /^(\s*\d*\s*)(\d*)(.*)/ ) {

				if ( $2 == $i ) {

					print OUT "$1$2\n";
				}
			}
		}

		close OUT;
		close CLUSTERS;

		$text -> insert( 'end', "\nNow sorting DCD files. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;


		if ( $^O eq 'linux' ) {

			`carma -v -sort $file $dcd_file`;
			`mv carma.reordered.dcd carma.cluster_0$i.dcd`;
		}
		else {

			`carma.exe -v -sort $file $dcd_file`;
			`move carma.reordered.dcd carma.cluster_0$i.dcd`;
		}

		my @backbone = ( 'C', 'CA', 'N', 'O', );

		my (
			 $seg_custom, $seg_atm, $seg, $res_custom, $res_atm,
			 $res, 		  $custom,  $atm, $nothing,
		);

		$text -> insert( 'end', "\nNow fitting DCD files. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		if ( $seg_id_flag ) {

			my @chains = split ' -segid ', $seg_id_flag;
			shift @chains;

			if ( $custom_id_flag ) {print '1';

				my @selected_atoms = split ' -atmid ', $custom_id_flag;
				shift @selected_atoms;

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(@chains)(\s*\d+\s*\w+\s*)(@selected_atoms)(\s+.*)};
				}

				open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						print OUT "$1$line_count$2$3$4$5$6\n";
						$line_count++;
					}
				}

				close OUT;
				close PSF;

				$flag = " -v -w -fit -index -atmid ALLID $seg_id_flag $psf_file carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$seg_custom = 1;
					$fit_check = 1;
				}
			}
			elsif ( $atm_id_flag ) {print '2';

				my @selected_atoms = ( 'C', 'CA', 'N', 'O', ) if ( $atm_id =~ /backbone/i );

				my $heavy = 0;
				$heavy = 1 if ( $atm_id_flag =~ /HEAVY/ );
				my $allid = 0;
				$allid = 1 if ( $atm_id_flag =~ /ALLID/ );

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(@chains)(\s*\d+\s*\w+\s*)(@selected_atoms)(\s+.*)} if ( @selected_atoms );
					$regex_var = qr{^(\s*)\d+(\s*)(@chains)(\s*\d+\s*\w+\s*)(\w+)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );
				}

				open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						my $line = $line_count . $2 . $3 . $4 . $5 . $6;

						if ( $heavy && $5 !~ /^H/ ) {

							print OUT "$line\n";
							$line_count++;
						}
						elsif ( $allid || @selected_atoms ) {

							printf OUT ( "%6d%s%s%s%s%s\n", $line_count, $2, $3, $4, $5, $6, );
							$line_count++;
						}
					}
				}

				close OUT;
				close PSF;

				$flag = " -v -w -fit -index -atmid ALLID $seg_id_flag $psf_file carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$seg_atm = 1;
					$fit_check = 1;
				}

				$heavy = 0;
				$allid = 0;
			}
			else {print '3';

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(@chains)(\s*\d+\s*\w+\s*)(@backbone)(\s+.*)};
				}

				open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						print OUT "$1$line_count$2$3$4$5$6\n";
						$line_count++;
					}
				}

				close OUT;
				close PSF;

				$flag = " -v -w -fit -atmid ALLID $seg_id_flag $psf_file carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$seg = 1;
					$fit_check = 1;
				}
			}
		}
		elsif ( $res_id_flag ) {

			if ( $custom_id_flag ) {print '4';

				my @selected_atoms = split ' -atmid ', $custom_id_flag;
				shift @selected_atoms;

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(Z)(\s*\d+\s*\w+\s*)(@selected_atoms)(\s+.*)};
				}

				open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						print OUT "$1$line_count\n";
						$line_count++;
					}
				}

				close PSF;
				close OUT;

				$flag = " -v -w -fit -atmid ALLID -index $seg_id_flag selected_residues.psf carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$res_custom = 1;
					$fit_check = 1;
				}
			}
			elsif ( $atm_id_flag ) {print '5';

				my @selected_atoms = ( 'C', 'CA', 'N', 'O', ) if ( $atm_id =~ /backbone/i );

				my $heavy = 0;
				$heavy = 1 if ( $atm_id_flag =~ /HEAVY/ );
				my $allid = 0;
				$allid = 1 if ( $atm_id_flag =~ /ALLID/ );

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(Z)(\s*\d+\s*\w+\s*)(@selected_atoms)(\s+.*)} if ( @selected_atoms );
					$regex_var = qr{^(\s*)\d+(\s*)(Z)(\s*\d+\s*\w+\s*)(\w*)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );
				}

				open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						my $line = $line_count . $2 . $3 . $4 . $5 . $6;

						if ( $heavy && $5 !~ /^H/ ) {

							print OUT "$line\n";
							$line_count++;
						}
						elsif ( $allid || @selected_atoms ) {

							printf OUT ( "%6d%s%s%s%s%s\n", $line_count, $2, $3, $4, $5, $6, );
							$line_count++;
						}
					}
				}

				close OUT;
				close PSF;

				$flag = " -v -w -fit -index -atmid ALLID $res_id_flag selected_residues.psf carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$res_atm = 1;
					$fit_check = 1;
				}

				$heavy = 0;
				$allid = 0;
			}
			else {print '6';

				my $line_count = 1;
				my $regex_var = '';

				{
					local $" = '|';
					$regex_var = qr{^(\s*)\d+(\s*)(Z)(\s*\d+\s*\w+\s*)(@backbone)(\s+.*)};
				}

				open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
				open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

				while ( <PSF> ) {

					if ( /$regex_var/ism ) {

						print OUT "$1$line_count$2$3$4$5$6\n";
						$line_count++;
					}
				}

				close OUT;
				close PSF;

				$flag = " -v -w -fit -index -atmid ALLID $res_id_flag selected_residues.psf carma.cluster_0$i.dcd";
				&carma ( 'auto' );

				if ( $all_done ) {

					$res = 1;
					$fit_check = 1;
				}
			}
		}
		elsif ( $custom_id_flag ) {print '7';

			my @selected_atoms = split ' -atmid ', $custom_id_flag;
			shift @selected_atoms;

			my $line_count = 1;
			my $regex_var = '';

			{
				local $" = '|';
				$regex_var = qr{^(\s*)\d+(\s*)(\w+)(\s*\d+\s*\w+\s+)(@selected_atoms)(\s+.*)};
			}

			open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
			open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";

			while ( <PSF> ) {

				if ( /$regex_var/ism ) {

					print OUT "$1$line_count$2$3$4$5$6\n";
					$line_count++;
				}
			}

			close PSF;
			close OUT;

			$flag = " -v -w -fit -atmid ALLID -index $psf_file carma.cluster_0$i.dcd";
			&carma ( 'auto' );

			if ( $all_done ) {

				$custom = 1;
				$fit_check = 1;
			}
		}
		elsif ( $atm_id_flag ) {print '8';

			my @selected_atoms = ( 'C', 'CA', 'N', 'O', ) if ( $atm_id =~ /BACKBONE/i );

			my $heavy = 0;
			$heavy = 1 if ( $atm_id_flag =~ /HEAVY/i );
			my $allid = 0;
			$allid = 1 if ( $atm_id_flag =~ /ALLID/i );

			my $line_count = 1;
			my $regex_var = '';

			{
				local $" = '|';
				$regex_var = qr{^(\s*)\d+(\s*)(\w+)(\s*\d+\s*\w+\s*)(@selected_atoms)(\s+.*)} if ( @selected_atoms );
				$regex_var = qr{^(\s*)\d+(\s*\w+\s*\d+\s*\w+\s*)(\w+)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );
			}

			open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
			open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

			while ( <PSF> ) {

				if ( /$regex_var/ ) {

					my $line = $line_count . $2 . $3 . $4 . $5 . $6;

					if ( $heavy && $3 !~ /^H/ ) {

						print OUT "$line\n";
						$line_count++;
					}
					elsif ( $allid || @selected_atoms ) {

						printf OUT ( "%6d%s%s%s\n", $line_count, $2, $3, $4, );
						$line_count++;
					}
				}
			}

			close OUT;
			close PSF;

			$flag = " -v -w -fit -index -atmid ALLID $psf_file carma.cluster_0$i.dcd";
			&carma ( 'auto' );

			if ( $all_done ) {

				$atm = 1;
				$fit_check = 1;
			}

			$heavy = 0;
			$allid = 0;
		}
		else {print '9';

			my $line_count = 1;
			my $regex_var = '';

			{
				local $" = '|';
				$regex_var = qr{^(\s*)\d+(\s*)(\w+)(\s*\d+\s*\w+\s*)(@backbone)(\s+.*)};
			}

			open PSF, '<', $psf_file || die "Cannot open $psf_file for reading: $!";
			open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

			while ( <PSF> ) {

				if ( /$regex_var/ism ) {

					print OUT "$1$line_count$2$3$4$5$6\n";
					$line_count++;
				}
			}

			close OUT;
			close PSF;

			$flag = " -v -w -fit -index -atmid ALLID $psf_file carma.cluster_0$i.dcd";
			&carma ( 'auto' );

			if ( $all_done ) {

				$nothing = 1;
				$fit_check = 1;
			}
		}

		if ( $fit_check ) {

			$text -> insert( 'end', "\nPerforming superposition of $i of $clusters dcd files.", 'valid', );
			$text -> see( 'end', );
			$mw -> update;

			if ( $^O eq 'linux' ) {

				`mv carma.fitted.dcd carma.fitted.cluster_0$i.dcd`;
			}
			else {

				`move carma.fitted.dcd carma.fitted.cluster_0$i.dcd`;
			}

			$flag = " -v -w -col -cov -dot -norm -super carma.fitted.cluster_0$i.dcd $psf_file";
			#~ $flag = " -v -w -col -cov -dot -norm -super carma.fitted.cluster_0$i.dcd selected_residues.psf" if ( $res_id_flag );
			&carma ( 'auto' );

			if ( $all_done ) {

				$super_check = 1;

				if ( $^O eq 'linux' ) {

					`mv carma.superposition.pdb superposition.cluster_0$i.pdb`;
					`mv carma.average.pdb average.cluster_0$i.pdb`;
				}
				else {

					`move carma.superposition.pdb superposition.cluster_0$i.pdb`;
					`move carma.average.pdb average.cluster_0$i.pdb`;
				}

				if ( $seg_custom || $seg_atm ) {

					$text -> insert( 'end', "\nThe fitting was performed for the selected atom types of the selected chains", 'info', );
					$seg_custom = 0;
					$seg_atm = 0;
				}
				elsif ( $seg ) {

					$text -> insert( 'end', "\nThe fitting was performed for the backbone atoms of the selected chains", 'info', );
					$seg = 0;
				}
				elsif ( $res_custom || $res_atm ) {

					$text -> insert( 'end', "\nThe fitting was performed for the selected atom types of the selected residues", 'info', );
					$res_custom = 0;
					$res_atm = 0;
				}
				elsif ( $res ) {

					$text -> insert( 'end', "\nThe fitting was performed for the backbone atoms of the selected residues", 'info', );
					$res = 0;
				}
				elsif ( $custom || $atm ) {

					$text -> insert( 'end', "\nThe fitting was performed for the selected atom types", 'info', );
					$custom = 0;
					$atm = 0;
				}
				elsif ( $nothing ) {

					$text -> insert( 'end', "\nThe fitting was performed for backbone atoms", 'info', );
					$nothing = 0;
				}
			}
			else {

				$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
				$text -> insert( 'end', getcwd . "\n", 'info', );
			}

			$text -> insert( 'end', "\nPerformed superposition of $clusters dcd files\n", 'info', ) if ( $all_done );
			$fit_check = 0;
		}
		else {

			$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
			$text -> insert( 'end', getcwd . "\n", 'info', );
		}
	}

	if ( $super_check ) {

		my $response = $mw -> messageBox( -message => "Would you like to view the created PDB files?",
										  -type => 'yesno',
										  -icon => 'question', );
		if ( $response eq 'Yes' ) {

			my $i = 0;
			my $j = 0;
			my @contents = '';

			my $temp_top = $mw -> Toplevel( -title => 'PDB files', );
			$temp_top -> geometry("$toplevel_position");
			opendir IMAGE_DIR, "." || die "Cannot open \'.\':$!";
			while ( readdir IMAGE_DIR ) {

				if ( /.*\.pdb$/i ) {

					$contents[$i] = $_;
					$i++;
				}
			}

			@contents = sort ( @contents );

			$temp_top -> Label( -text => "\nContents of the folder", ) -> pack;
			$temp_top -> Label( -text => getcwd, ) -> pack;
			$temp_top -> Label( -text => "\nClick on the file you want to view\n", ) -> pack;

			my $lb = $temp_top -> Listbox( -selectmode => "single", ) -> pack( -anchor => 'center', );

			$temp_top -> Button( -text => 'Done',
								 -command => [ $temp_top => 'destroy' ], )
								 -> pack( -side => 'bottom',
										  -anchor => 'center', );

			$lb -> insert( 'end', @contents, );
			$lb -> bind( '<Button-1>', sub {

											my $selection = $lb -> get( $lb -> curselection() );
											system ( "$pdb_viewer $selection &" ) if ( $^O eq 'linux' );
											`start $selection` if ( $^O ne 'linux' );
										} );
		}
		$super_check = 0;
	}
}

###################################################################################################
###   Draw the window for sorting DCD files                                                     ###
###################################################################################################

sub sort_window {

	my $srt_cluster = '';
	my $top_srt;

	our $remember_psf;
	our $remember_dcd;

	if ( !Exists ( $top_srt ) ) {

		$top_srt = $mw -> Toplevel( -title => 'Sorting of dcd files', );
		$top_srt -> geometry("$toplevel_position");
		$top_srt -> protocol( 'WM_DELETE_WINDOW' => sub { $top_srt -> withdraw }, );

		my $frame_srt1 = $top_srt -> Frame() -> pack( -expand => 1, -fill => 'x', );

		$frame_srt1 -> Label( -text => 'Cluster: ', )-> grid( -row => 1, -column => 1, -sticky => 'w', );
		$frame_srt1 -> Entry( -textvariable => \$srt_cluster, )-> grid( -row => 1, -column => 2, -sticky => 'w', );
		$frame_srt1 -> Label( -text => 'PSF file to use: ', )-> grid( -row => 2, -column => 1, -sticky => 'w', );
		$frame_srt1 -> Entry( -textvariable => \$remember_psf, -width => 65, )-> grid( -row => 2, -column => 2, -sticky => 'w', );
		$frame_srt1 -> Button( -text => 'Change', -command => sub { &open_file ( "psf" ); $remember_psf = $psf_file; }, )-> grid( -row => 2, -column => 3, );
		$frame_srt1 -> Label( -text => 'DCD file to use: ', )-> grid( -row => 3, -column => 1, -sticky => 'w', );
		$frame_srt1 -> Entry( -textvariable => \$remember_dcd, -width => 65, )-> grid( -row => 3, -column => 2, -sticky => 'w', );
		$frame_srt1 -> Button( -text => 'Change', -command => sub { &open_file ( "dcd" ); $remember_dcd = $dcd_file; }, )-> grid( -row => 3, -column => 3, );

		my $frame_srt2 = $top_srt -> Frame()-> pack( -expand => 0, );

		$frame_srt2 -> Button( -text => 'Return',
							   -command => [ $top_srt => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_srt2 -> Button( -text => 'Run',
							   -command => sub {

						&create_dir;

						open CLUSTERS, "carma.clusters.dat" || die "Cannot open carma.clusters.dat for reading\n";
						open C_01, ">C_01.dat" || die "Cannot open C_01.dat for writing\n";

						while ( <CLUSTERS> ) {

							if ( /(\s*\d*\s*)(\d*)(.*)/ ) {

								if ( $2 == $srt_cluster ) {

									print C_01 "$1$2$3\n";
								}
							}
						}

						close CLUSTERS;
						close C_01;

						$flag = " -v -sort C_01.dat";
						&carma ( "sort" );

						if ( $all_done ) {

							$text -> insert( 'end', "Sorting finished", 'valid' );
							$text -> see( 'end', );
						}
						else {

							$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
							$text -> see( 'end', );
						}
		}, )
		-> pack( -side => 'right', );
	}
	else {

		$top_srt -> deiconify;
		$top_srt -> raise;
	}
}

###################################################################################################
###   Draw the window for eigenvector and eigenvalue calculations                               ###
###################################################################################################

sub eigen_window {

	my $eig_dot = '';
	my $eig_norm = '';
	my $eig_3d = '';
	my $eig_use = '';
	my $eig_out = '';
	my $eig_out_first = '';
	my $eig_out_last = '';
	my $eig_out_step = '';
	my $eig_play_max = '';
	my $eig_play_min = '';
	my $top_eig;

	if ( !Exists ( $top_eig ) ) {

		$top_eig = $mw -> Toplevel( -title => 'Eigenvector and eigenvalue calculations', );
		$top_eig -> geometry("$toplevel_position");
		$top_eig -> protocol( 'WM_DELETE_WINDOW' => sub { $top_eig -> withdraw }, );

		my $frame_eig2 = $top_eig -> Frame() -> pack( -expand => 1, -fill => 'x', );
		my $frame_eig3 = $top_eig -> Frame() -> pack( -expand => 1, -fill => 'x', );
		my $frame_eig4 = $top_eig -> Frame() -> pack( -expand => 1, -fill => 'x', );

		&radiobuttons ( $frame_eig2 );
		&checkbuttons ( $frame_eig3 );
		&otherbuttons ( $frame_eig4 );

		$frame_eig1 = $top_eig -> Frame() -> pack( -fill => 'x', );

		$frame_eig1 -> Checkbutton( -text => 'Calculate dot',
									-variable => \$eig_dot,
									-offvalue => '',
									-onvalue => " -dot", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_eig1 -> Checkbutton( -text => 'Calculate normalised matrices',
									-variable => \$eig_norm,
									-offvalue => '',
									-onvalue => " -norm", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_eig1 -> Checkbutton( -text => 'Create 3D landscapes',
									-variable => \$eig_3d,
									-offvalue => '',
									-onvalue => " -3d", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_eig1 -> Checkbutton( -text => 'Use previously calculated eigenvalues',
									-variable => \$eig_use,
									-offvalue => '',
									-onvalue => " -use", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_eig1 -> Checkbutton( -text => 'Output projections to a file',
									-variable => \$eig_out,
									-offvalue => '',
									-onvalue => " -out", )
									-> pack( -side => 'top', -anchor => 'w', );

		$frame_eig1 -> Label( -text => 'First: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eig1 -> Entry( -textvariable => \$eig_out_first, )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eig1 -> Label( -text => 'Last: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eig1 -> Entry( -textvariable => \$eig_out_last, )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eig1 -> Label( -text => 'Step: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eig1 -> Entry( -textvariable => \$eig_out_step, )-> pack( -side => 'left', -anchor => 'w', );

		if ( -e "carma.PCA.fluctuations.dat" ) {

			&play;
		}

		my $frame_eig5 = $top_eig -> Frame()-> pack( -expand => 0, );

		$frame_eig5 -> Button( -text => 'Return',
							   -command => [ $top_eig => 'withdraw' ], )
							   -> pack( -side => 'left', );
		$frame_eig5 -> Button( -text => 'Run',
							   -command => sub {

						$top_eig -> destroy;

						$seg_id_flag = '' if $seg_id_flag;

						foreach ( @seg_ids ) {

							if ( defined ( $_ ) ) {

								$seg_id_flag = $seg_id_flag . $_;
							}
						}

						if ( $seg_id_flag ) {

							$flag = " -v -cov -eigen $eig_dot $eig_norm $eig_3d $eig_art $eig_play $eig_play_vector $eig_art_vectors $eig_art_frames $eig_play_max $eig_play_min $eig_use $eig_out $eig_out_first $eig_out_last $eig_out_step $atm_id_flag $seg_id_flag $res_id_flag";
						}
						else {

							$flag = " -v -cov -eigen $eig_dot $eig_norm $eig_3d $eig_art $eig_play $eig_play_vector $eig_art_vectors $eig_art_frames $eig_play_max $eig_play_min $eig_use $eig_out $eig_out_first $eig_out_last $eig_out_step $atm_id_flag $res_id_flag";
						}
						&create_dir;

						$text -> insert( 'end', "\nNow calculating eigenvectors and eigenvalues. ", 'valid', );
						$text -> see( 'end', );
						$mw -> update;

						&carma;

						if ( $all_done ) {

							$text -> insert( 'end', "Calculation finished", 'valid' );
							$text -> see( 'end', );
						}
						else {

							$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
							$text -> see( 'end', );
						}
		}, )
		-> pack( -side => 'right', );

	}
	else {

		$top_eig -> deiconify;
		$top_eig -> raise;

		unless ( @amplitudes ) {

			&play;
		}
	}
}

###################################################################################################
###   Draw the window for eigenvector and eigenvalue calculations                               ###
###################################################################################################

sub varcov_window {

	my $var_dot = '';
	my $var_norm = '';
	my $var_mass = '';
	my $var_first = '';
	my $var_last = '';
	my $var_step = '';
	my $var_min = '';
	my $var_max = '';
	my $var_reverse = '';
	my $var_first_flag = '';
	my $var_last_flag = '';
	my $var_step_flag = '';
	my $var_min_flag = '';
	my $var_max_flag = '';
	my $top_var;

	if ( !Exists ( $top_var ) ) {

		$top_var = $mw -> Toplevel( -title => 'Variance Covariance Matrix', );
		$top_var -> geometry("$toplevel_position");
		$top_var -> protocol( 'WM_DELETE_WINDOW' => sub { $top_var -> withdraw }, );

		my $frame_var1 = $top_var -> Frame() -> pack( -expand => 1, -fill => 'x', );
		my $frame_var2 = $top_var -> Frame() -> pack( -expand => 1, -fill => 'x', );
		my $frame_var3 = $top_var -> Frame() -> pack( -expand => 1, -fill => 'x', );

		&radiobuttons ( $frame_var1 );
		&checkbuttons ( $frame_var2 );
		&otherbuttons ( $frame_var3 );

		my $frame_var4 = $top_var -> Frame() -> pack( -fill => 'x', );
		$frame_var4 -> Label( -text => 'Various Options' )
							  -> pack( -side => 'top', );

		$frame_var4 -> Checkbutton( -text => 'Calculate dot',
									-variable => \$var_dot,
									-offvalue => '',
									-onvalue => " -dot", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_var4 -> Checkbutton( -text => 'Calculate normalised matrices',
									-variable => \$var_norm,
									-offvalue => '',
									-onvalue => " -norm", )
									-> pack( -side => 'top', -anchor => 'w', );
		$frame_var4 -> Checkbutton( -text => 'Calculate mass-weighted matrices',
									-variable => \$var_mass,
									-offvalue => '',
									-onvalue => " -mass", )
									-> pack( -side => 'top', -anchor => 'w', );

		my $frame_var5 = $top_var -> Frame()-> pack( -expand => 0, );

		$frame_var5 -> Label( -text => 'First: ', )
							  -> grid( -row => 1, -column => 1, );
		$frame_var5 -> Entry( -textvariable => \$var_first, )
							  -> grid( -row => 1, -column => 2, );
		$frame_var5 -> Label( -text => 'Last: ', )
							  -> grid( -row => 2, -column => 1, );
		$frame_var5 -> Entry( -textvariable => \$var_last, )
							  -> grid( -row => 2, -column => 2, );
		$frame_var5 -> Label( -text => 'Step: ', )
							  -> grid( -row => 3, -column => 1, );
		$frame_var5 -> Entry( -textvariable => \$var_step, )
							  -> grid( -row => 3, -column => 2, );

		$frame_var5 -> Label( -text => 'Min: ', )
							  -> grid( -row => 1, -column => 3, );
		$frame_var5 -> Entry( -textvariable => \$var_min, )
							  -> grid( -row => 1, -column => 4, );
		$frame_var5 -> Label( -text => 'Max: ', )
							  -> grid( -row => 2, -column => 3, );
		$frame_var5 -> Entry( -textvariable => \$var_max, )
							  -> grid( -row => 2, -column => 4, );
		$frame_var5 -> Checkbutton( -text => 'Reverse',
									-variable => \$var_reverse,
									-offvalue => '',
									-onvalue => " -reverse", )
									-> grid( -row => 3, -column => 3, );

		my $frame_var6 = $top_var -> Frame() -> pack( -expand => 0, );

		$frame_var6 -> Button( -text => 'Return',
							   -command => [ $top_var => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_var6 -> Button( -text => 'Run',
							   -command => sub {

						$top_var -> destroy;

						if ( $var_first ) {

							$var_first_flag = " -first $var_first";
						}
						else {

							$var_first_flag = '';
						}

						if ( $var_last ) {

							$var_last_flag = " -last $var_last";
						}
						else {

							$var_last_flag = '';
						}

						if ( $var_step ) {

							$var_step_flag = " -step $var_step";
						}
						else {

							$var_step_flag = '';
						}

						if ( $var_min ) {

							$var_min_flag = " -min $var_min";
						}
						else {

							$var_min_flag = '';
						}

						if ( $var_max ) {

							$var_max_flag = " -max $var_max";
						}
						else {

							$var_max_flag = '';
						}

						$seg_id_flag = '' if $seg_id_flag;

						foreach ( @seg_ids ) {

							if ( defined ( $_ ) ) {

								$seg_id_flag = $seg_id_flag . $_;
							}
						}

						if ( $seg_id_flag ) {

							$flag = " -v -w -col -cov $var_dot $var_norm $var_mass $var_max_flag $var_min_flag $var_step_flag $var_last_flag $var_first_flag $var_reverse $atm_id_flag $seg_id_flag $res_id_flag";
						}
						else {

							$flag = " -v -w -col -cov $var_dot $var_norm $var_mass $var_max_flag $var_min_flag $var_step_flag $var_last_flag $var_first_flag $var_reverse $atm_id_flag $res_id_flag";
						}

						&create_dir;

						$text -> insert( 'end', "\nNow calculating variance covariance matrix. ", 'valid', );
						$text -> see( 'end', );
						$mw -> update;

						&carma;

						if ( $all_done ) {

							$text -> insert( 'end', "Calculation finished", 'valid' );
							$text -> see( 'end', );
						}
						else {

							$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
							$text -> see( 'end', );
						}
		}, )
		-> pack( -side => 'right', );
	}
	else {

		$top_var -> deiconify;
		$top_var -> raise;
	}
}

###################################################################################################
###   Extract the maximum and minimum amplitutes from the carma.fluctuations file               ###
###################################################################################################

sub play {

	if ( -e "carma.PCA.fluctuations.dat" ) {

		open FLUCTUATIONS, "carma.PCA.fluctuations.dat" || die "Cannot open carma.PCA.fluctuations.dat for reading\n";

		my $i = 0;
		while ( <FLUCTUATIONS> ) {

			if ( /\s*\d*\s*(-?\d*\.\d*)/ ) {

				$amplitudes[$i] = $1;
				$i++;
			}
		}
		close FLUCTUATIONS;

		my @sorted_amplitudes = sort { $a <=> $b } @amplitudes;
		my $eig_play_max = $sorted_amplitudes[0];
		my $eig_play_min = $sorted_amplitudes[$1-1];

		my $frame_eigA = $top_eig -> Frame() -> pack( -fill => 'x', -after => $frame_eig1, );

		my $frame_eigB = $top_eig -> Frame() -> pack( -fill => 'x', -after => $frame_eig1, );

		$frame_eigA -> Checkbutton( -text => 'Motion of the eigenvector',
									-variable => \$eig_play,
									-offvalue => '',
									-onvalue => " -play", )
									-> pack( -side => 'top', -anchor => 'w', );

		$frame_eigA -> Label( -text => 'Eigenvector: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigA -> Entry( -textvariable => \$eig_play_vector, )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigA -> Label( -text => 'Max: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigA -> Entry( -textvariable => \$eig_play_max, )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigA -> Label( -text => 'Min: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigA -> Entry( -textvariable => \$eig_play_min, )-> pack( -side => 'left', -anchor => 'w', );

		$frame_eigB -> Checkbutton( -text => 'Artificial',
									-variable => \$eig_art,
									-offvalue => '',
									-onvalue => " -art", )
									-> pack( -side => 'top', -anchor => 'w', );

		$frame_eigB -> Label( -text => 'Vectors: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigB -> Entry( -textvariable => \$eig_art_vectors, )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigB -> Label( -text => 'Frames: ', )-> pack( -side => 'left', -anchor => 'w', );
		$frame_eigB -> Entry( -textvariable => \$eig_art_frames, )-> pack( -side => 'left', -anchor => 'w', );
	}
}

###################################################################################################
###   Draw the window for viewing the .ps images                                                ###
###################################################################################################

sub image_window {

	my $i = 0;
	my $j = 0;
	my @contents = '';
	#~ my $toplevel_position = "260x290" . $toplevel_position;

	my $image_top = $mw -> Toplevel( -title => 'Latest Images', );
	$image_top -> geometry("$toplevel_position");
	opendir IMAGE_DIR, "." || die "Cannot open \'.\':$!";
	while ( readdir IMAGE_DIR ) {

		if ( /.*\.ps$/ ) {

			$contents[$i] = $_;
			$i++;
		}
	}

	@contents = sort ( @contents );

	$image_top -> Label( -text => "\nClick on the image you want to view\n", ) -> pack;

	my $lb = $image_top -> Listbox( -selectmode => "single",
									-width => 27, )
									-> pack( -anchor => 'center', );

	$image_top -> Button( -text => 'Return',
						  -command => [ $image_top => 'destroy' ], )
						  -> pack( -side => 'bottom',
								   -anchor => 'center', );

	$lb -> insert( 'end', @contents, );
	$lb -> bind( '<Button-1>', sub {

									my $selection = $lb -> get( $lb -> curselection() );
									system ( "$ps_viewer $selection &" ) if ( $^O eq 'linux' );
									`start $selection` if ( $^O ne 'linux' );
								} );
}

###################################################################################################
###   Draw the window for residue selection                                                     ###
###################################################################################################

sub select_residues {

	my $pos = '';
	my $prev_line = '';

	&create_dir;
	open PSF_FILE, $psf_file || die "Cannot open $psf_file for reading\n";
	open OUT, ">selected_residues.psf" || die "Cannot open selected_residues.psf for writing\n";

	# As soon as '!NATOM' is met, reading #
	# of the .psf file and output to the  #
	# custom psf file is stopped          #
	while ( <PSF_FILE> ) {

		print OUT $_;
		if ( /\!NATOM/ ) {

			last;
		}
	}

	# For every resid bar                  #
	for ( my $i = 0 ; $i <= $resid_bar_count ; $i++ ) {

		# If the $pos variable exists move to  #
		# the point of the filehandle defined  #
		# by it                                #
		if ( $pos ) {

			seek PSF_FILE, $pos, 0;
			print OUT $prev_line;
		}

		# Else continue reading the .psf file  #
		# from the next line after the one     #
		# containing '!NATOM'                  #
		while ( <PSF_FILE> ) {

			# If the pattern is met                #
			if ( /^(\s*\d*\s*)($dropdown_value[$i])(\s*)(\d*)(.*)$/ ) {

				# And the residue number equals the    #
				# upper limit set by the user store in #
				# $pos the location in the filehandle  #
				# and in $prev_line the line just read #
				# and exit the while loop              #
				if ( $4 == $upper_res_limit[$i] + 1 ) {

					$pos = tell;
					$prev_line = $_;
					last;
				}

				# If the line contains a residue whose #
				# number falls between the limits set  #
				# by the user export that line to the  #
				# custom .psf file while changing the  #
				# chain id to 'Z'                      #
				if ( $4 >= $lower_res_limit[$i] && $4 <= $upper_res_limit[$i] ) {

					print OUT "$1Z$3$4$5\n";
				}
				# Otherwise export the line as is      #
				else {

					print OUT $_;
				}
			}
		}
	}

	# Set the position of the filehandle   #
	# to the one specified by $pos, print  #
	# the line which would have been       #
	# skipped if not for $prev_line, and   #
	# print the rest of the .psf to the    #
	# custom file                          #
	seek PSF_FILE, $pos, 0;
	print OUT $prev_line;

	while ( <PSF_FILE> ) {

		print OUT $_;
	}

	close OUT;
	close PSF_FILE;

	$have_custom_psf = 1;

	$res_id_flag = " -segid Z";
	$active_run_buttons = 1;
	$text -> insert ( 'end', "\nYou have submitted a residue selection which resulted in the creation of a new .psf file.\n", 'info' );
	$text -> insert ( 'end', "While the \"Change\" radiobutton is selected all the calculations will be made with the custom .psf file\n", 'info' );
	$text -> insert ( 'end', "By selecting the \"All\" radiobutton the selected .psf file reverts to the one originally specified\n", 'info' );
	$text -> see( 'end', );
	$active_psf_label -> configure( -text => "Active .psf: selected_residues.psf", );
}

###################################################################################################
###   Create fit.index                                                                          ###
###################################################################################################

sub create_fit_index {

	# The same as above but for the index  #
	# subroutine                           #

	if ( $_[0] ) {

		open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
	}
	else {

		open PSF, '<', "carma.selected_atoms.psf" || die "Cannot open carma.selected_atoms.psf for reading:$!\n";
	}

	open OUT, ">fit.index" || die "Cannot open fit.index for writing:$!\n";

	$index_num_atoms = 0;
	while ( <PSF_FILE> ) {

		if ( /(\d*)\s*\!NATOM/ ) {

			$index_num_atoms = $1;
			last;
		}
	}

	my $fit_atom_count = 1;
	my $index_pos = '';
	for ( my $i = 0 ; $i <= $index_bar_count ; $i++ ) {

		if ( $index_pos ) {

			seek PSF_FILE, $index_pos, 0;
		}

		while ( my $index_line = <PSF_FILE> ) {

			if ( $index_line =~ /^(\s*)(\d*)(.*)$/ ) {

				if ( $2 > $upper_fit_limit[$i] ) {

					$index_pos = tell;
					last;
				}

				if ( $2 >= $lower_fit_limit[$i] && $2 <= $upper_fit_limit[$i] ) {

					$index_line = sprintf ( "%8d%s\n", $fit_atom_count, $3, );
					print OUT "$index_line";
					$fit_atom_count++;
				}
			}
		}
	}

	close OUT;
	close PSF_FILE;
}

###################################################################################################
###   Create new 'select residues bar'                                                          ###
###################################################################################################

sub resid_window {

	my $top_res;

	if ( !Exists ( $top_res ) ) {

		foreach ( keys %num_residues ) {

			$text -> insert( 'end', "\n$num_residues{$_} residues in chain $_\n", 'info' );
			$text -> see( 'end', );
		}

		$top_res = $mw -> Toplevel( -title => 'Residue Selection', );
		$top_res -> geometry("$toplevel_position");
		$top_res -> protocol( 'WM_DELETE_WINDOW' => sub { $top_res -> withdraw });

		my $frame_res0 = $top_res -> Frame( -borderwidth => 3,
											-relief => 'groove',)
											-> pack( -fill => 'x', );

		$frame_res1[$resid_bar_count] = $top_res -> Frame() -> pack();

		$frame_res1[$resid_bar_count] -> Button( -text => 'Add..',
												 -width => 10,
												 -command => sub {

			$resid_bar_count++;
			$frame_res1[$resid_bar_count] = $top_res -> Frame() -> pack() unless ( $resid_bar_count == 0 );

			&add_resid_bar;

			foreach ( keys %num_residues ) {

				$dropdown[$resid_bar_count] -> insert( 'end', $_ );
			}

			if ( $resid_bar_count >= 1 ) {

				$frame_res1[$resid_bar_count] -> Button( -text => 'Remove',
														 -width => 10,
														 -command => sub {

														$frame_res1[$resid_bar_count] -> destroy;
														$resid_bar_count--;
													}, )
												   -> grid( -row => "$resid_row", -column => "$resid_column" + 5, );
			}
			}, )
		-> grid( -row => 2, -column => 6, );

		my $frame_res2 = $top_res -> Frame() -> pack( -side => 'bottom', -expand => 0, );

		$frame_res2 -> Button( -text => 'Return',
							   -command => [ $top_res => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_res2 -> Button( -text => 'Submit',
							   -command => sub {

								   &select_residues;
								   if ( $f4_b ) {

									   $f4_b -> destroy;
									   $f4_b = $f4 -> Frame() -> pack;
									   for ( my $i = 0 ; $i <= $resid_bar_count ; $i++ ) {

										   $f4_b -> Label( -text => "$lower_res_limit[$i] - $upper_res_limit[$i], $dropdown_value[$i]" )
														   -> pack( -anchor => 'w', );
										}
								   }
								   else {

									   $f4_b = $f4 -> Frame() -> pack;
									   for ( my $i = 0 ; $i <= $resid_bar_count ; $i++ ) {

										   $f4_b -> Label( -text => "$lower_res_limit[$i] - $upper_res_limit[$i], $dropdown_value[$i]" )
														   -> pack( -anchor => 'w', );
										}
								   }

								   $top_res -> withdraw;
							   }, )
							   -> pack( -side => 'right', );

		$resid_row = 1;
		$resid_column = 4;

		$frame_res0 -> Label( -text => "\nPlease specify the selections in ascending order for each chain\n", ) -> pack;

		&add_resid_bar;


	}
	else {

		$top_res -> deiconify;
		$top_res -> raise;
	}
}

###################################################################################################
###   Create a new bar for residue selection                                                    ###
###################################################################################################

sub add_resid_bar {

	# Create a new frame everytime a new   #
	# bar is vreated and insert the bar in #
	# that frame                           #
	$resid_row++;
	$resid_column = 1;

	$frame_res1[$resid_bar_count] -> Label( -text => 'From: ', )
											-> grid( -row => "$resid_row", -column => "$resid_column", );
	$frame_res1[$resid_bar_count] -> Entry( -textvariable => \$lower_res_limit[$resid_bar_count], )
											-> grid( -row => "$resid_row", -column => "$resid_column" + 1, );
	$frame_res1[$resid_bar_count] -> Label( -text => 'To: ', )
											-> grid( -row => "$resid_row", -column => "$resid_column" + 2, );
	$frame_res1[$resid_bar_count] -> Entry( -textvariable => \$upper_res_limit[$resid_bar_count], )
											-> grid( -row => "$resid_row", -column => "$resid_column" + 3, );

	$dropdown[$resid_bar_count] = $frame_res1[$resid_bar_count] -> BrowseEntry( -label => "in chain: ",
																				-variable => \$dropdown_value[$resid_bar_count], )
																				-> grid( -row => "$resid_row", -column => "$resid_column" + 4, );
}

###################################################################################################
###   Create a new bar for fit.index creation                                                   ###
###################################################################################################

sub add_index_bar {

	$index_row++;
	$index_column = 1;

	$frame_fit_index4[$index_bar_count] -> Label( -text => 'From: ', )
												  -> grid( -row => "$index_row", -column => "$index_column", );
	$frame_fit_index4[$index_bar_count] -> Entry( -textvariable => \$lower_fit_limit[$index_bar_count], )
												  -> grid( -row => "$index_row", -column => "$index_column" + 1, );
	$frame_fit_index4[$index_bar_count] -> Label( -text => 'To: ', )
												  -> grid( -row => "$index_row", -column => "$index_column" + 2, );
	$frame_fit_index4[$index_bar_count] -> Entry( -textvariable => \$upper_fit_limit[$index_bar_count], )
												  -> grid( -row => "$index_row", -column => "$index_column" + 3, );
}

###################################################################################################
###   Draw the window for solute entropy calculation                                            ###
###################################################################################################

sub entropy_window {

	my $ent_step = '';
	my $ent_mass = '';
	my $ent_temp = '';
	my $lower_ent_limit = '';
	my $upper_ent_limit = '';
	my $top_ent;

	my @a_entropy;
	my @s_entropy;

	if ( !Exists ( $top_ent ) ) {

		# Divide the number of frames in the   #
		# .dcd header by 10 and round it up    #
		unless ( $ent_step ) {

			$ent_step = int ( ( $header / 10 ) );
		}

		$top_ent = $mw -> Toplevel( -title => 'Solute entropy calculation', );
		$top_ent -> geometry("$toplevel_position");
		$top_ent -> protocol( 'WM_DELETE_WINDOW' => sub { $top_ent -> withdraw }, );

		my $frame_ent1 = $top_ent -> Frame( -borderwidth => 3,
											-relief => 'groove',)
											-> pack( -fill => 'x', );

		my $mass_check = $frame_ent1 -> Checkbutton( -text => "Mass",
													 -variable => \$ent_mass,
													 -onvalue => '-mass',
													 -offvalue => '', )
													 -> grid( -row => 3, -column => 2, );
		$mass_check -> select;

		$frame_ent1 -> Label( -text => 'Step: ', )
							  -> grid( -row => 1, -column => 1, );
		$frame_ent1 -> Entry( -textvariable => \$ent_step, )
							  -> grid( -row => 1, -column => 2, );
		$frame_ent1 -> Label( -text => 'Temperature (K): ', )
							  -> grid( -row => 2, -column => 1, );
		$frame_ent1 -> Entry( -textvariable => \$ent_temp, )
							  -> grid( -row => 2, -column => 2, );

		my $frame_ent2 = $top_ent -> Frame() -> pack( -fill => 'x', );
		my $frame_ent3 = $top_ent -> Frame() -> pack( -fill => 'x', );
		my $frame_ent4 = $top_ent -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_ent2 );
		&checkbuttons ( $frame_ent3 );
		&otherbuttons ( $frame_ent4 );

		my $frame_ent5 = $top_ent -> Frame() -> pack( -expand => 0, );

		$frame_ent5 -> Button( -text => 'Return',
							   -command => [ $top_ent => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_ent5 -> Button( -text => 'Run',
							   -command => sub {

				# Make ten repeat runs each time using #
				# $ent_step more steps. This means in  #
				# the first run the first tenth of the #
				# frames will be used, in the second   #
				# the first fifth...                   #
				$top_ent -> destroy;

				$text -> insert( 'end', "\nNow calculating entropy. ", 'valid', );
				$text -> see( 'end', );
				$mw -> update;

				# The result of the $i * $ent_step     #
				# multiplication is the number of the  #
				# frame that will be used after the    #
				# ' -last' flag                        #
				for ( my $i = 0 ; ( $i * $ent_step ) < $header ; $i++ ) {

					# If that number exceeds the number of #
					# frames in the .dcd header then that  #
					# number will be used instead          #
					if ( ( $header - ( $i * $ent_step ) ) > $ent_step ) {

						$lower_ent_limit = 1;
						$upper_ent_limit = ( ( $i + 1 ) * $ent_step );
						$text -> insert( 'end', "\nCalculating entropy from frame $lower_ent_limit to frame $upper_ent_limit", 'valid' );
						$text -> see( 'end', );

						$seg_id_flag = '' if $seg_id_flag;

						foreach ( @seg_ids ) {

							if ( defined ( $_ ) ) {

								$seg_id_flag = $seg_id_flag . $_;
							}
						}

						if ( $seg_id_flag ) {

							$flag = " -v -cov -eigen $ent_mass -temp $ent_temp $atm_id_flag $seg_id_flag $res_id_flag -first $lower_ent_limit -last $upper_ent_limit";
						}
						else {

							$flag = " -v -cov -eigen $ent_mass -temp $ent_temp $atm_id_flag $res_id_flag -first $lower_ent_limit -last $upper_ent_limit";
						}
						&create_dir;
						&carma;

					}
					else {

						$lower_ent_limit = 1;
						$upper_ent_limit = $header;

						$seg_id_flag = '' if $seg_id_flag;

						foreach ( @seg_ids ) {

							if ( defined ( $_ ) ) {

								$seg_id_flag = $seg_id_flag . $_;
							}
						}

						if ( $seg_id_flag ) {

							$flag = " -v -cov -eigen $ent_mass -temp $ent_temp $atm_id_flag $seg_id_flag $res_id_flag -first $lower_ent_limit -last $upper_ent_limit";
						}
						else {

							$flag = " -v -cov -eigen $ent_mass -temp $ent_temp $atm_id_flag $res_id_flag -first $lower_ent_limit -last $upper_ent_limit";
						}
						$text -> insert( 'end', "\nCalculating entropy from frame $lower_ent_limit to frame $upper_ent_limit", 'valid' );
						$text -> see( 'end', );
						&create_dir;
						&carma;
					}
					open READ_ENTROPY, "carma.out.copy" || die "Cannot open carma.out.copy for reading:$!";
					open WRITE_ENTROPY, ">>carma_entropy.dat" || die "Cannot open carma_entropy.dat for writing:$!";

					# Parse the output file for the lines  #
					# containing the results and save them #
					# in a file named 'carma_entropy.dat'  #
					# and two arrays, one for every type   #
					# of entropy calculated by carma       #
					while ( <READ_ENTROPY> ) {

						if ( /Entropy \(Andricioaei\)(\s*)is (\d*\.\d*) (\(J\/molK\))/ ) {

							$a_entropy[$i] = $2;
							printf WRITE_ENTROPY ("%3d %15.5f\n", $i + 1, $2, );
							$text -> insert( 'end', "$_", 'valid' );
							$text -> see( 'end', );
						}
						if ( /Entropy \(Schlitter\)(\s*)is (\d*\.\d*) (\(J\/molK\))/ ) {

							$s_entropy[$i] = $2;
							printf WRITE_ENTROPY ("%3d %15.5f\n", $i + 1, $2, );
							$text -> insert( 'end', "$_", 'valid' );
							$text -> see( 'end', );
						}
					}
					close READ_ENTROPY;

					if ( $upper_ent_limit == $header ) {

						if ( $all_done ) {

							$text -> insert( 'end', "\nCalculation finished", 'valid' );
							$text -> see( 'end', );
						}
						else {

							$text -> insert( 'end' , "\nSomething went wrong\nCheck carma.out.copy for details\n", 'error' );
							$text -> see( 'end', );
						}
						$upper_ent_limit = 0;
					}
				}
				close WRITE_ENTROPY;

				# If arrays for both entropies exist   #
				# overwrite the entropy file with the  #
				# contents of those arrays             #
				if ( @a_entropy && @s_entropy ) {

					open WRITE_ENTROPY, ">carma_entropy.dat" || die "Cannot open carma_entropy.dat for writing";
					my $k = 0;
					foreach ( @s_entropy ) {

						$k++;
					}

					for ( my $j = 0 ; $j < $k ; $j++ ) {

						printf WRITE_ENTROPY ( "%3d %15.5f %15.5f\n", $j + 1, $a_entropy[$j], $s_entropy[$j], );
					}
					close WRITE_ENTROPY;
				}
		}, )
		-> pack( -side => 'right', );
	}
	else {

		$top_ent -> deiconify;
		$top_ent -> raise;
	}
}

###################################################################################################
###   Create PDB files for the specified frames                                                 ###
###################################################################################################

sub pdb_window {

	my $pdb_step;
	my $top_pdb;

	if ( !Exists ( $top_pdb ) ) {

		unless ( $pdb_step ) {

			$pdb_step = int ( ( $header / 10 ) );
		}

		$top_pdb = $mw -> Toplevel( -title => 'Extract selected PDB files', );
		$top_pdb -> geometry("$toplevel_position");
		$top_pdb -> protocol( 'WM_DELETE_WINDOW' => sub { $top_pdb -> withdraw }, );

		my $frame_pdb1 = $top_pdb -> Frame( -borderwidth => 3,
											-relief => 'groove',)
											-> pack( -fill => 'x', );

		$frame_pdb1 -> Label( -text => 'Step: ', )
							  -> grid( -row => 1, -column => 1, );
		$frame_pdb1 -> Entry( -textvariable => \$pdb_step, )
							  -> grid( -row => 1, -column => 2, );

		my $frame_pdb2 = $top_pdb -> Frame() -> pack( -fill => 'x', );
		my $frame_pdb3 = $top_pdb -> Frame() -> pack( -fill => 'x', );
		my $frame_pdb4 = $top_pdb -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_pdb2 );
		&checkbuttons ( $frame_pdb3 );
		&otherbuttons ( $frame_pdb4 );

		my $frame_pdb5 = $top_pdb -> Frame() -> pack( -expand => 0, );

		$frame_pdb5 -> Button( -text => 'Return',
							   -command => [ $top_pdb => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_pdb5 -> Button( -text => 'Run',
							   -command => sub {

		$top_pdb -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -pdb $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag -step $pdb_step";
		}
		else {

			$flag = " -v -pdb $atm_id_flag $res_id_flag $custom_id_flag @seg_ids -step $pdb_step";
		}
		&create_dir;

		$text -> insert( 'end', "\nNow extracting pdb files. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;
		}, )
		-> pack( -side => 'right', );

	}
	else {

		$top_pdb -> deiconify;
		$top_pdb -> raise;
	}

}

###################################################################################################
###   Draw the window for distance maps                                                         ###
###################################################################################################

sub rms_window {

	my $rms_first = '';
	my $rms_first_flag = '';
	my $rms_last = '';
	my $rms_last_flag = '';
	my $rms_step = '';
	my $rms_step_flag = '';
	my $rms_min = '';
	my $rms_min_flag = '';
	my $rms_max = '';
	my $rms_max_flag = '';
	my $rms_mrms = '';
	my $rms_mrms_flag = '';
	my $rms_reverse = '';
	my $average_ps_file = '';
	my $rmsdev_ps_file = '';
	my $top_rms;

	if ( !Exists ( $top_rms ) ) {

		unless ( $rms_step ) {

			$rms_step = $rmsd_step;
		}

		$top_rms = $mw -> Toplevel( -title => 'Average distance and rms deviation from them', );
		$top_rms -> geometry("$toplevel_position");
		$top_rms -> protocol( 'WM_DELETE_WINDOW' => sub { $top_rms -> withdraw }, );

		my $frame_rms1 = $top_rms -> Frame() -> pack( -fill => 'x', );
		my $frame_rms2 = $top_rms -> Frame() -> pack( -fill => 'x', );
		my $frame_rms3 = $top_rms -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_rms1 );
		&checkbuttons ( $frame_rms2 );
		&otherbuttons ( $frame_rms3 );

		my $frame_rms4 = $top_rms -> Frame()-> pack( -expand => 0, );

		$frame_rms4 -> Label( -text => 'First: ', )
							  -> grid( -row => 1, -column => 1, );
		$frame_rms4 -> Entry( -textvariable => \$rms_first, )
							  -> grid( -row => 1, -column => 2, );
		$frame_rms4 -> Label( -text => 'Last: ', )
							  -> grid( -row => 2, -column => 1, );
		$frame_rms4 -> Entry( -textvariable => \$rms_last, )
							  -> grid( -row => 2, -column => 2, );
		$frame_rms4 -> Label( -text => 'Step: ', )
							  -> grid( -row => 3, -column => 1, );
		$frame_rms4 -> Entry( -textvariable => \$rms_step, )
							  -> grid( -row => 3, -column => 2, );

		$frame_rms4 -> Label( -text => 'Min: ', )
							  -> grid( -row => 1, -column => 3, );
		$frame_rms4 -> Entry( -textvariable => \$rms_min, )
							  -> grid( -row => 1, -column => 4, );
		$frame_rms4 -> Label( -text => 'Max: ', )
							  -> grid( -row => 2, -column => 3, );
		$frame_rms4 -> Entry( -textvariable => \$rms_max, )
							  -> grid( -row => 2, -column => 4, );
		$frame_rms4 -> Label( -text => 'Mrms: ', )
							  -> grid( -row => 3, -column => 3, );
		$frame_rms4 -> Entry( -textvariable => \$rms_mrms, )
							  -> grid( -row => 3, -column => 4, );

		$frame_rms4 -> Checkbutton( -text => 'Reverse',
									-variable => \$rms_reverse,
									-offvalue => '',
									-onvalue => " -reverse", )
									-> grid( -row => 4, -column => 1, );

		my $frame_rms5 = $top_rms -> Frame() -> pack( -expand => 0, );

		$frame_rms5 -> Button( -text => 'Return',
							   -command => [ $top_rms => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_rms5 -> Button( -text => 'Run',
							   -command => sub {

		if ( $rms_first ) {

			$rms_first_flag = " -first $rms_first";
		}
		else {

			$rms_first_flag = '';
		}

		if ( $rms_last ) {

			$rms_last_flag = " -last $rms_last";
		}
		else {

			$rms_last_flag = '';
		}

		if ( $rms_step ) {

			$rms_step_flag = " -step $rms_step";
		}
		else {

			$rms_step_flag = '';
		}

		if ( $rms_min ) {

			$rms_min_flag = " -min $rms_min";
		}
		else {

			$rms_min_flag = '';
		}

		if ( $rms_max ) {

			$rms_max_flag = " -max $rms_max";
		}
		else {

			$rms_max_flag = '';
		}

		if ( $rms_mrms ) {

			$rms_mrms_flag = " -mrms $rms_mrms";
		}
		else {

			$rms_mrms_flag = '';
		}

		$top_rms -> destroy;

		if ( $rms_first && $rms_last && $rms_first > 0 && $rms_first == $rms_last ) {


			$seg_id_flag = '' if $seg_id_flag;

			foreach ( @seg_ids ) {

				if ( defined ( $_ ) ) {

					$seg_id_flag = $seg_id_flag . $_;
				}
			}

			if ( $seg_id_flag ) {

				$flag = " -v -w -col $rms_first_flag $rms_last_flag $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
			}
			else {

				$flag = " -v -w -col $rms_first_flag $rms_last_flag $atm_id_flag $custom_id_flag $res_id_flag";
			}
		}
		else {

			$seg_id_flag = '' if $seg_id_flag;

			foreach ( @seg_ids ) {

				if ( defined ( $_ ) ) {

					$seg_id_flag = $seg_id_flag . $_;
				}
			}

			if ( $seg_id_flag ) {

				$flag = " -v -w -col -rms $rms_first_flag $rms_last_flag $rms_step_flag $rms_min_flag $rms_max_flag $rms_mrms_flag $rms_reverse $atm_id_flag $custom_id_flag $seg_id_flag $res_id_flag";
			}
			else {

				$flag = " -v -w -col -rms $rms_first_flag $rms_last_flag $rms_step_flag $rms_min_flag $rms_max_flag $rms_mrms_flag $rms_reverse $atm_id_flag $custom_id_flag $res_id_flag";
			}
		}
		&create_dir;

		$text -> insert( 'end', "\nNow calculating average Ca - Ca distances. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;
		open RMS_OUT, "carma.out.copy" || die "Cannot open carma.out.copy for reading";
		while ( <RMS_OUT> ) {

			if ( /Writing postscript file (\w*\.dcd\.averag.ps)/ ) {

				$average_ps_file = $1;
			}
			if ( /Writing postscript file (\w*\.dcd\.rmsdev.ps)/ ) {

				$rmsdev_ps_file = $1;
			}
		}
		close RMS_OUT;

		if ( $^O eq 'linux' ) {

			`carma $average_ps_file $rmsdev_ps_file`;
		}
		else {

			`carma.exe $average_ps_file $rmsdev_ps_file`;
		}

		$text -> insert( 'end', "Calculation finished\nUse \'View Images\'", 'valid' );
		$text -> see( 'end', );
		$image_menu -> configure( -state => 'normal', );
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_rms -> deiconify;
		$top_rms -> raise;
	}
}

###################################################################################################
###   Draw the window for radius of gyration                                                    ###
###################################################################################################

sub rgr_window {

	my $top_rgr;

	if ( !Exists ( $top_rgr ) ) {

		$top_rgr = $mw -> Toplevel( -title => 'Radius of gyration', );
		$top_rgr -> geometry("$toplevel_position");
		$top_rgr -> protocol( 'WM_DELETE_WINDOW' => sub { $top_rgr -> withdraw }, );

		my $frame_rgr1 = $top_rgr -> Frame() -> pack( -fill => 'x', );
		my $frame_rgr2 = $top_rgr -> Frame() -> pack( -fill => 'x', );
		my $frame_rgr3 = $top_rgr -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_rgr1 );
		&checkbuttons ( $frame_rgr2 );
		&otherbuttons ( $frame_rgr3 );

		my $frame_rgr4 = $top_rgr -> Frame() -> pack( -expand => 0, );

		$frame_rgr4 -> Button( -text => 'Return',
							   -command => [ $top_rgr => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_rgr4 -> Button( -text => 'Run',
							   -command => sub {

		$top_rgr -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -rg $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -rg $atm_id_flag $res_id_flag $custom_id_flag";
		}

		&create_dir;

		$text -> insert( 'end', "\nNow calculating radious of gyration. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;

		if ( $all_done ) {

			$text -> insert( 'end', "Calculation finished", 'valid' );
			$text -> see( 'end', );
		}
		else {

			$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
			$text -> see( 'end', );
		}
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_rgr -> deiconify;
		$top_rgr -> raise;
	}
}

###################################################################################################
###   Draw the window for distances                                                             ###
###################################################################################################

sub dis_window {

	my $dis_atom1 = '';
	my $dis_atom2 = '';
	my $top_dis;

	if ( !Exists ( $top_dis ) ) {

		$top_dis = $mw -> Toplevel( -title => 'Distances', );
		$top_dis -> geometry("$toplevel_position");
		$top_dis -> protocol( 'WM_DELETE_WINDOW' => sub { $top_dis -> withdraw }, );

		my $frame_dis1 = $top_dis -> Frame( -borderwidth => 3,
										 -relief => 'groove',)
										 -> pack( -fill => 'x', );

		$frame_dis1 -> Label( -text => 'Atom 1', )
							  -> grid( -row => 1, -column => 1, );
		$frame_dis1 -> Entry( -textvariable => \$dis_atom1, )
							  -> grid( -row => 2, -column => 1, );

		$frame_dis1 -> Label( -text => 'Atom 2', )
							  -> grid( -row => 1, -column => 2, );
		$frame_dis1 -> Entry( -textvariable => \$dis_atom2, )
							  -> grid( -row => 2, -column => 2, );

		my $frame_dis2 = $top_dis -> Frame() -> pack( -fill => 'x', );
		my $frame_dis3 = $top_dis -> Frame() -> pack( -fill => 'x', );
		my $frame_dis4 = $top_dis -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_dis2 );
		&checkbuttons ( $frame_dis3 );
		&otherbuttons ( $frame_dis4 );

		my $frame_dis5 = $top_dis -> Frame() -> pack( -expand => 0, );

		$frame_dis5 -> Button( -text => 'Return',
							   -command => [ $top_dis => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_dis5 -> Button( -text => 'Run',
							   -command => sub {

		$top_dis -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -dist $dis_atom1 $dis_atom2 $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -dist $dis_atom1 $dis_atom2 $atm_id_flag $custom_id_flag $res_id_flag";
		}

		&create_dir;

		$text -> insert( 'end', "\nNow calculating distances. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;

		if ( $all_done ) {

			$text -> insert( 'end', "Calculation finished", 'valid' );
			$text -> see( 'end', );
		}
		else {

			$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
			$text -> see( 'end', );
		}
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_dis -> deiconify;
		$top_dis -> raise;
	}
}

###################################################################################################
###   Draw the window for bending angles                                                        ###
###################################################################################################

sub bnd_window {

	my $bnd_atom1 = '';
	my $bnd_atom2 = '';
	my $bnd_atom3 = '';
	my $top_bnd;

	if ( !Exists ( $top_bnd ) ) {

		$top_bnd = $mw -> Toplevel( -title => 'Bending angles', );
		$top_bnd -> geometry("$toplevel_position");
		$top_bnd -> protocol( 'WM_DELETE_WINDOW' => sub { $top_bnd -> withdraw }, );

		my $frame_bnd1 = $top_bnd -> Frame( -borderwidth => 3,
											-relief => 'groove',)
											-> pack( -fill => 'x', );

		$frame_bnd1 -> Label( -text => 'Atom 1', )
							  -> grid( -row => 1, -column => 1, );
		$frame_bnd1 -> Entry( -textvariable => \$bnd_atom1, )
							  -> grid( -row => 2, -column => 1, );

		$frame_bnd1 -> Label( -text => 'Atom 2', )
							  -> grid( -row => 1, -column => 2, );
		$frame_bnd1 -> Entry( -textvariable => \$bnd_atom2, )
							  -> grid( -row => 2, -column => 2, );

		$frame_bnd1 -> Label( -text => 'Atom 3', )
							  -> grid( -row => 1, -column => 3, );
		$frame_bnd1 -> Entry( -textvariable => \$bnd_atom3, )
							  -> grid( -row => 2, -column => 3, );

		my $frame_bnd2 = $top_bnd -> Frame() -> pack( -fill => 'x', );
		my $frame_bnd3 = $top_bnd -> Frame() -> pack( -fill => 'x', );
		my $frame_bnd4 = $top_bnd -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_bnd2 );
		&checkbuttons ( $frame_bnd3 );
		&otherbuttons ( $frame_bnd4 );

		my $frame_bnd5 = $top_bnd -> Frame() -> pack( -expand => 0, );

		$frame_bnd5 -> Button( -text => 'Return',
							   -command => [ $top_bnd => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_bnd5 -> Button( -text => 'Run',
							   -command => sub {

		$top_bnd -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -bend $bnd_atom1 $bnd_atom2 $bnd_atom3 $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -bend $bnd_atom1 $bnd_atom2 $bnd_atom3 $atm_id_flag $custom_id_flag $res_id_flag";
		}

		&create_dir;

		$text -> insert( 'end', "\nNow calculating bend angles. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;

		if ( $all_done ) {

			$text -> insert( 'end', "Calculation finished", 'valid' );
			$text -> see( 'end', );
		}
		else {

			$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
			$text -> see( 'end', );
		}
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_bnd -> deiconify;
		$top_bnd -> raise;
	}
}

###################################################################################################
###   Draw the window for torsion angles                                                        ###
###################################################################################################

sub tor_window {

	my $tor_atom1 = '';
	my $tor_atom2 = '';
	my $tor_atom3 = '';
	my $tor_atom4 = '';
	my $top_tor;

	if ( !Exists ( $top_tor ) ) {

		$top_tor = $mw -> Toplevel( -title => 'Torsion angles', );
		$top_tor -> geometry("$toplevel_position");
		$top_tor -> protocol( 'WM_DELETE_WINDOW' => sub { $top_tor -> withdraw }, );

		my $frame_tor1 = $top_tor -> Frame( -borderwidth => 3,
											-relief => 'groove',)
											-> pack( -fill => 'x', );

		$frame_tor1 -> Label( -text => 'Atom 1', )
							  -> grid( -row => 1, -column => 1, );
		$frame_tor1 -> Entry( -textvariable => \$tor_atom1, )
							  -> grid( -row => 2, -column => 1, );
		$frame_tor1 -> Label( -text => 'Atom 2', )
							  -> grid( -row => 1, -column => 2, );
		$frame_tor1 -> Entry( -textvariable => \$tor_atom2, )
							  -> grid( -row => 2, -column => 2, );
		$frame_tor1 -> Label( -text => 'Atom 3', )
							  -> grid( -row => 1, -column => 3, );
		$frame_tor1 -> Entry( -textvariable => \$tor_atom3, )
							  -> grid( -row => 2, -column => 3, );
		$frame_tor1 -> Label( -text => 'Atom 4', )
							  -> grid( -row => 1, -column => 4, );
		$frame_tor1 -> Entry( -textvariable => \$tor_atom4, )
							  -> grid( -row => 2, -column => 4, );

		my $frame_tor2 = $top_tor -> Frame() -> pack( -fill => 'x', );
		my $frame_tor3 = $top_tor -> Frame() -> pack( -fill => 'x', );
		my $frame_tor4 = $top_tor -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_tor2 );
		&checkbuttons ( $frame_tor3 );
		&otherbuttons ( $frame_tor4 );

		my $frame_tor5 = $top_tor -> Frame() -> pack( -expand => 0, );

		$frame_tor5 -> Button( -text => 'Return',
							   -command => [ $top_tor => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_tor5 -> Button( -text => 'Run',
							   -command => sub {

		$top_tor -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -torsion $tor_atom1 $tor_atom2 $tor_atom3 $tor_atom4 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -torsion $tor_atom1 $tor_atom2 $tor_atom3 $tor_atom4 $atm_id_flag $res_id_flag $custom_id_flag";
		}

		&create_dir;

		$text -> insert( 'end', "\nNow calculating torsion angles. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;

		if ( $all_done ) {

			$text -> insert( 'end', "Calculation finished", 'valid' );
			$text -> see( 'end', );
		}
		else {

			$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
			$text -> see( 'end', );
		}
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_tor -> deiconify;
		$top_tor -> raise;
	}
}

###################################################################################################
###   Draw the window for ion and water distribution maps                                       ###
###################################################################################################

sub map_window {

	my $map_ang_x = '';
	my $map_ort_x = '';
	my $map_ang_y = '';
	my $map_ort_y = '';
	my $map_ang_z = '';
	my $map_ort_z = '';
	my $map_grid_spacing = '';
	my $top_map;

	if ( -e "fit.index" ) {

		if ( !Exists ( $top_map ) ) {

			$top_map = $mw -> Toplevel( -title => 'Ion and water distribution maps', );
			$top_map -> geometry("$toplevel_position");
			$top_map -> protocol( 'WM_DELETE_WINDOW' => sub { $top_map -> withdraw }, );

			my $frame_map1 = $top_map -> Frame( -borderwidth => 3,
												-relief => 'groove',)
												-> pack( -fill => 'x', );

			$frame_map1 -> Label( -text => 'Limits', ) -> pack;

			my $frame_map2 = $top_map -> Frame() -> pack( -expand => 0, );

			$frame_map2 -> Label( -text => 'Angstrom' )
								  -> grid( -row => 2, -column => 1, );
			$frame_map2 -> Label( -text => 'Orthogonal' )
								  -> grid( -row => 3, -column => 1, );
			$frame_map2 -> Label( -text => 'X' )
								  -> grid( -row => 1, -column => 2, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ang_x )
								  -> grid( -row => 2, -column => 2, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ort_x )
								  -> grid( -row => 3, -column => 2, -columnspan => 2, );
			$frame_map2 -> Label( -text => 'Y' )
								  -> grid( -row => 1, -column => 4, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ang_y )
								  -> grid( -row => 2, -column => 4, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ort_y )
								  -> grid( -row => 3, -column => 4, -columnspan => 2, );
			$frame_map2 -> Label( -text => 'Z' )
								  -> grid( -row => 1, -column => 6, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ang_z )
								  -> grid( -row => 2, -column => 6, -columnspan => 2, );
			$frame_map2 -> Entry( -textvariable => \$map_ort_z )
								  -> grid( -row => 3, -column => 6, -columnspan => 2, );
			$frame_map2 -> Label( -text => 'Grid spacing' )
								  -> grid( -row => 1, -column => 8, );
			$frame_map2 -> Entry( -textvariable => \$map_grid_spacing )
								  -> grid( -row => 2, -column => 8, );

			my $frame_map3 = $top_map -> Frame() -> pack( -fill => 'x', );
			my $frame_map4 = $top_map -> Frame() -> pack( -fill => 'x', );
			my $frame_map5 = $top_map -> Frame() -> pack( -fill => 'x', );

			&radiobuttons ( $frame_map3 );
			&checkbuttons ( $frame_map4 );
			&otherbuttons ( $frame_map5 );

			my $frame_map6 = $top_map -> Frame() -> pack( -expand => 0, );

			$frame_map6 -> Button( -text => 'Return',
								   -command => [ $top_map => 'withdraw' ], )
								   -> pack( -side => 'left', );

			$frame_map6 -> Button( -text => 'Run',
								   -command => sub {

			$top_map -> destroy;

			$seg_id_flag = '' if $seg_id_flag;

			foreach ( @seg_ids ) {

				if ( defined ( $_ ) ) {

					$seg_id_flag = $seg_id_flag . $_;
				}
			}

			if ( $seg_id_flag ) {

				$flag = " -v -w -map $map_ang_x $map_ort_x $map_ang_y $map_ort_y $map_ang_z $map_ort_z $map_grid_spacing $atm_id_flag $custom_id_flag $seg_id_flag $res_id_flag";
			}
			else {

				$flag = " -v -w -map $map_ang_x $map_ort_x $map_ang_y $map_ort_y $map_ang_z $map_ort_z $map_grid_spacing $atm_id_flag $custom_id_flag $res_id_flag";
			}

			&create_dir;

			$text -> insert( 'end', "\nNow mapping water and ions. ", 'valid', );
			$text -> see( 'end', );
			$mw -> update;

			&carma;

			if ( $all_done ) {

				$text -> insert( 'end', "Calculation finished", 'valid' );
				$text -> see( 'end', );
			}
			else {

				$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
				$text -> see( 'end', );
			}
			}, )-> pack( -side => 'right', );
		}
		else {

			$top_map -> deiconify;
			$top_map -> raise;
		}
	}
	else {

		my $response = $mw -> messageBox( -message => "No \'fit.index\' file found in the working directory. Would you like to load one?",
										  -type => 'yesno',
										  -icon => 'question', );
		my $filetype = undef;
		if ( $response eq 'Yes' ) {

			if ( $^O eq 'linux' ) {

				$filetype = [ ['Fitting index files', '.index'] ];
			}
			else {

				$filetype = [['Fitting index files',  '.index'], ['Fitting index files',  '.index']];
			}

			my $file = $mw -> getOpenFile( -filetypes => $filetype, );

			if ( $file =~ /\w*\.index/ ) {

				$file = abs_path ( $file );
				&create_dir;

				if ( $^O eq 'linux' ) {

					`cp $file .`;
				}
				else {

					`copy $file .`;
				}
			}
		}
	}
}

###################################################################################################
###   Draw the window for bending angles                                                        ###
###################################################################################################

sub sur_window {

	my $top_sur;

	if ( !Exists ( $top_sur ) ) {

		$top_sur = $mw -> Toplevel( -title => 'Surface area', );
		$top_sur -> geometry("$toplevel_position");
		$top_sur -> protocol( 'WM_DELETE_WINDOW' => sub { $top_sur -> withdraw }, );

		my $frame_sur1 = $top_sur -> Frame() -> pack( -fill => 'x', );
		$frame_sur2 = $top_sur -> Frame() -> pack( -fill => 'x', );
		my $frame_sur3 = $top_sur -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_sur1 );
		&checkbuttons ( $frame_sur2 );
		&otherbuttons ( $frame_sur3 );

		my $frame_sur4 = $top_sur -> Frame() -> pack( -expand => 0, );

		$frame_sur4 -> Button( -text => 'Return',
							   -command => [ $top_sur => 'withdraw' ], )
							   -> pack( -side => 'left', );

		$frame_sur4 -> Button( -text => 'Run',
							   -command => sub {

		$top_sur -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -surf $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -surf $atm_id_flag $custom_id_flag $res_id_flag";
		}

		&create_dir;

		$text -> insert( 'end', "\nNow calculating surface area. ", 'valid', );
		$text -> see( 'end', );
		$mw -> update;

		&carma;

		if ( $all_done ) {

			$text -> insert( 'end', "Calculation finished", 'valid' );
			$text -> see( 'end', );
		}
		else {

			$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
			$text -> see( 'end', );
		}
		}, )-> pack( -side => 'right', );
	}
	else {

		$top_sur -> deiconify;
		$top_sur -> raise;
	}
}

###################################################################################################
###   Draw the window for fitting                                                               ###
###################################################################################################

sub fit_window {

	my $no_fit = '';
	my $ref = '';
	my $ref_fit_entry = '';
	my $ref_atom_num = '';

	our $top_fit;

	if ( !Exists ( $top_fit ) ) {

		unless ( $dcd_count ) {

			$dcd_count = -1;
		}

		$top_fit = $mw -> Toplevel( -title => 'Fitting', );
		$top_fit -> geometry("$toplevel_position");
		$top_fit -> protocol( 'WM_DELETE_WINDOW' => sub { $top_fit -> withdraw });

		my $frame_fit1 = $top_fit -> Frame() -> pack( -fill => 'x', );
		my $frame_fit2 = $top_fit -> Frame() -> pack( -fill => 'x', );
		my $frame_fit3 = $top_fit -> Frame() -> pack( -fill => 'x', );

		&radiobuttons ( $frame_fit1 );
		&checkbuttons ( $frame_fit2 );
		&otherbuttons ( $frame_fit3 );

		my $frame_fit2a = $top_fit -> Frame() -> pack( -fill => 'x', );
		my $frame_fit4 = $top_fit -> Frame() -> pack( -fill => 'x', );

		$frame_fit2a -> Label( -text => 'Optional settings' )
							   -> pack( -side => 'bottom', );

		$frame_fit4 -> Checkbutton( -text => "Use frame as ref: ",
									-variable => \$ref,
									-offvalue => '',
									-onvalue => " -ref",
									-command => sub { $ref_fit_entry -> configure( -state => 'normal', ); }, )
									-> grid( -row => 2, -column => 1, );

		my $ref_fit_entry = $frame_fit4 -> Entry( -textvariable => \$ref_atom_num,
												  -state => 'disabled', )
												  -> grid( -row => 2, -column => 2, );

		$frame_fit4 -> Checkbutton( -text => 'No fit',
									-variable => \$no_fit,
									-offvalue => '',
									-onvalue => " -nofit", )
									-> grid( -row => 2, -column => 3, );

		my $frame_fit5 = $top_fit -> Frame() -> pack( -side => 'bottom', -expand => 0, );

		$frame_fit5 -> Button( -text => 'Return',
							   -command => sub { $top_fit -> withdraw; }, )
							   -> pack( -side => 'left', );

		$frame_fit5 -> Button( -text => 'Run',
							   -command => sub {

			$seg_id_flag = '' if $seg_id_flag;

			foreach ( @seg_ids ) {

				if ( defined ( $_ ) ) {

					$seg_id_flag = $seg_id_flag . $_;
				}
			}

			if ( $seg_id_flag ) {

				$flag = " -w -v -fit $ref $ref_atom_num $no_fit $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
			}
			else {

				$flag = " -w -v -fit $ref $ref_atom_num $no_fit $atm_id_flag $custom_id_flag $res_id_flag";
			}

			&create_dir;

			$text -> insert( 'end', "\nNow performing fitting. ", 'valid', );
			$text -> see( 'end', );
			$mw -> update;

			&carma ( "fit" );
			if ( $all_done ) {

				$text -> insert( 'end', "Fitting complete\n", 'valid' );
				$text -> see( 'end', );

				my $response = $frame_fit1 -> messageBox( -message => "Would you like to use this PSF - DCD pair in other calculations?",
														  -type => 'yesno',
														  -icon => 'question', );

				if ( $response eq "Yes" ) {

					$dcd_count++;
					$active_dcd_label -> configure( -text => "Active .dcd: carma_fitted_$dcd_count.dcd", );
					$active_psf_label -> configure( -text => "Active .psf: carma_fitted_$dcd_count.psf", );
					if ( $^O eq 'linux' ) {

						`mv carma.fitted.dcd carma_fitted_$dcd_count.dcd`;
						`mv carma.selected_atoms.psf carma_fitted_$dcd_count.psf`;
					}
					else {

						`move carma.fitted.dcd carma_fitted_$dcd_count.dcd`;
						`move carma.selected_atoms.psf carma_fitted_$dcd_count.psf`;
					}
				$top_fit -> withdraw;
				}
				else {

					$frame_fit1 -> messageBox( -type => "ok",
											   -message => "These files will not be used in any calculations and will be overwritten next time you perform a fitting", );
				}
			}
			else {

				$top_fit -> withdraw;
				$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
				$text -> see( 'end', );
			}
		}, )
		-> pack( -side => 'right', );
	}
	else {

		$top_fit -> deiconify;
		$top_fit -> raise;
	}
}

###################################################################################################
###   Draw the window for selective fitting                                                     ###
###################################################################################################

sub fit_index_window {

	my $ref_index = '';
	my $ref_fit_index_entry = '';
	my $ref_index_atom_num = '';
	my $no_fit_index = '';
	my $index_atm_id = '';
	my $index_atm_id_flag = '';
	my $top_fit_index;

	my @index_seg_ids;

	if ( !Exists ( $top_fit_index ) ) {

		unless ( $dcd_count ) {

			$dcd_count = -1;
		}

		$top_fit_index = $mw -> Toplevel( -title => 'Selective Fitting', );
		$top_fit_index -> geometry("$toplevel_position");
		$top_fit_index -> protocol( 'WM_DELETE_WINDOW' => sub { $top_fit_index -> withdraw });

		my $frame_fit_index1 = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index2 = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index8 = $top_fit_index -> Frame() -> pack( -fill => 'x', );

		$frame_fit_index1 -> Label( -text => "\nATOMS TO OUTPUT TO DCD\n", ) -> pack;

		&radiobuttons ( $frame_fit_index1 );
		&checkbuttons ( $frame_fit_index2 );
		&otherbuttons ( $frame_fit_index8 );

		my $frame_fit_index2a = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index3 = $top_fit_index -> Frame() -> pack( -expand => 1, -fill => 'both', );

		$frame_fit_index2a -> Label( -text => 'Optional settings' )
									 -> pack( -side => 'bottom', );

		$frame_fit_index3 -> Checkbutton( -text => "Use frame as ref: ",
										  -variable => \$ref_index,
										  -offvalue => '',
										  -onvalue => " -ref",
										  -command => sub { $ref_fit_index_entry -> configure( -state => 'normal', ); }, )
										  -> pack( -side => 'left', -anchor => 'w', );

		my $ref_fit_index_entry = $frame_fit_index3 -> Entry( -textvariable => \$ref_index_atom_num,
															  -state => 'disabled', )
															  -> pack( -side => 'left', -anchor => 'w', );

		$frame_fit_index3 -> Checkbutton( -text => 'No fit',
										  -variable => \$no_fit_index,
										  -offvalue => '',
										  -onvalue => " -nofit", )
										  -> pack( -side => 'left', -anchor => 'w', );

		$frame_fit_index3 -> Button( -text => 'Submit',
									 -command => sub {

										 &create_dir;
										 if ( $^O eq 'linux' ) {

											$seg_id_flag = '' if $seg_id_flag;

											foreach ( @seg_ids ) {

												if ( defined ( $_ ) ) {

													$seg_id_flag = $seg_id_flag . $_;
												}
											}

											if ( $seg_id_flag ) {

												 `carma -v -w -first 1 -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $psf_file $dcd_file`;
											 }
											 else {

												 `carma -v -w -first 1 -last 1 $atm_id_flag $custom_id_flag $res_id_flag $psf_file $dcd_file`;
											 }
										 }
										 else {

											$seg_id_flag = '' if $seg_id_flag;

											foreach ( @seg_ids ) {

												if ( defined ( $_ ) ) {

													$seg_id_flag = $seg_id_flag . $_;
												}
											}

											if ( $seg_id_flag ) {

												 `carma.exe -v -w -first 1 -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag \"dcd_file.dcd\" \"psf_file.psf\"`;
											 }
											 else {

												 `carma.exe -v -w -first 1 -last 1 $atm_id_flag $res_id_flag $custom_id_flag \"dcd_file.dcd\" \"psf_file.psf\"`;
											 }
										 }
									 }, ) -> pack( -anchor => 'center', );

		my $frame_fit_index4 = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index5 = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index9 = $top_fit_index -> Frame() -> pack( -fill => 'x', );
		my $frame_fit_index7 = $top_fit_index -> Frame() -> pack( -fill => 'x', );

		$frame_fit_index4 -> Label( -text => "\nATOMS TO USE FOR THE FITTING\n", ) -> pack;

		$frame_fit_index4 -> Label( -text => 'Atmid Selection' ) -> pack;

		my @index_radiobuttons = ( 'CA', 'Backbone', 'Heavy', 'All atoms', 'Custom selection', );
		my @index_radio_b;

		for my $i ( 0 .. $#index_radiobuttons ) {

			$index_radio_b[$i] = $frame_fit_index4 -> Radiobutton( -text => $index_radiobuttons[$i],
																   -value => $index_radiobuttons[$i],
																   -variable => \$index_atm_id,
																   -command => sub {

												if ( $index_atm_id eq 'CA' ) {

													$index_atm_id_flag = "";
													$custom_selection = 0;
												}
												elsif ( $index_atm_id eq 'Backbone' ) {

													$index_atm_id_flag = " -atmid C -atmid CA -atmid N -atmid O";
													$custom_selection = 0;
												}
												elsif ( $index_atm_id eq 'Heavy' ) {

													$index_atm_id_flag = " -atmid HEAVY";
													$custom_selection = 0;
												}
												elsif ( $index_atm_id eq 'All atoms' ) {

													$index_atm_id_flag = " -atmid ALLID";
													$custom_selection = 0;
												}
												}, );

			$index_radio_b[$i] -> pack( -side => 'left', -anchor => 'w', );
		}

		$index_radio_b[4] -> configure( -command => \&raise_custom_window, );

		$frame_fit_index5 -> Label( -text => 'Segid Selection', ) -> pack;

		my @index_check_b;

		my $index_count = 0;

		for my $j ( 0 .. $#unique_chain_ids ) {

			$index_check_b[$j] = $frame_fit_index5 -> Checkbutton( -text => $unique_chain_ids[$j],
																   -variable => \$index_seg_ids[$j],
																   -offvalue => '',
																   -onvalue => " -segid $unique_chain_ids[$j]",
																   -command => sub {

							 if ( $index_seg_ids[$j] ne '' ) {

								 $index_count++;
							 }
							 else {

								 $index_count--;
							 }

							 if ( $unique_chain_ids[$j] =~ /^[A-Z]$/ && $index_seg_ids[$j] ne '' ) {

								 $active_run_buttons = 'yes';
								 $dpca_run_button -> configure( -state => 'normal', ) if ( $dpca_run_button );
							 }
							 elsif ( $unique_chain_ids[$j] =~ /^[A-Z]$/ && $index_count < 1 ) {

								 $active_run_buttons = 'no';
								 $dpca_run_button -> configure( -state => 'disabled', ) if ( $dpca_run_button );
							 }
							 }, );

			$index_check_b[$j] -> pack( -side => 'left', -anchor => 'w', );
		}

		my @index_otherbuttons = ( 'All', 'Change', );
		my @index_other;

		$frame_fit_index9 -> Label( -text => 'Resid Selection', ) -> pack;

		for my $k ( 0 .. $#index_otherbuttons ) {

			$index_other[$k] = $frame_fit_index9 -> Radiobutton( -text => "$index_otherbuttons[$k]",
																 -value => $index_otherbuttons[$k], );

			$index_other[$k] -> pack( -side => 'left', -anchor => 'w', );
		}

		$index_other[0] -> configure( -command => sub { $have_custom_psf = 'no'; } );
		$index_other[1] -> configure( -command => \&resid_window, );

		$frame_fit_index7 -> Label( -text => "Atom selection", ) -> pack;

		$index_bar_count = 0;
		$frame_fit_index4[$index_bar_count] = $top_fit_index -> Frame() -> pack();

		$frame_fit_index4[$index_bar_count] -> Button( -text => 'Add..',
													   -width => 10,
													   -command => sub {

			$index_bar_count++;
			$frame_fit_index4[$index_bar_count] = $top_fit_index -> Frame() -> pack() unless ( $index_bar_count == 0 );

			&add_index_bar;

			if ( $index_bar_count >= 1 ) {

				$frame_fit_index4[$index_bar_count] -> Button( -text => 'Remove',
															   -width => 10,
															   -command => sub {

														$frame_fit_index4[$index_bar_count] -> destroy;
														$index_bar_count--;
													}, )
												   -> grid( -row => "$index_row", -column => "$index_column" + 5, );
			}
			}, )
		-> grid( -row => 2, -column => 6, );

		my $index_row = 1;
		my $index_column = 4;

		#~ $frame_res0 -> Label( -text => "\nPlease specify the selections in ascending order for each chain\n", ) -> pack;

		&add_index_bar;

		my $frame_fit_index6 = $top_fit_index -> Frame() -> pack( -side => 'bottom', -expand => 0, );

		$frame_fit_index6 -> Button( -text => 'Return',
									 -command => sub { $top_fit_index -> withdraw; }, )
									 -> pack( -side => 'left', );

		$frame_fit_index6 -> Button( -text => 'Run',
									 -command => sub {

			&create_fit_index;

			if ( $^O eq 'linux' ) {

				foreach ( @index_seg_ids ) {

					if ( defined ( $_ ) ) {

						$index_seg_id_flag = $index_seg_id_flag . $_;
					}
				}

				if ( $seg_id_flag ) {

					my $num_atom_check = `carma -v -w -first 1 -last 1 $index_atm_id_flag $custom_id_flag $index_seg_id_flag $dcd_file $psf_file`;
				}
				else {

					my $num_atom_check = `carma -v -w -first 1 -last 1 $index_atm_id_flag $custom_id_flag $dcd_file $psf_file`;
				}
			}
			else {

				foreach ( @index_seg_ids ) {

					if ( defined ( $_ ) ) {

						$index_seg_id_flag = $index_seg_id_flag . $_;
					}
				}

				if ( $seg_id_flag ) {

					my $num_atom_check = `carma.exe -v -w -first 1 -last 1 $index_atm_id_flag $custom_id_flag $index_seg_id_flag \"dcd_file.dcd\" \"psf_file.psf\"`;
				}
				else {

					my $num_atom_check = `carma.exe -v -w -first 1 -last 1 $index_atm_id_flag $custom_id_flag \"dcd_file.dcd\" \"psf_file.psf\"`;
				}
			}

			my $index_fitting_num_atoms = 0;
			my $num_atom_check = '';

			if ( $num_atom_check =~ /3?3?m?(\d*).*declared in the PSF file/ ) {

				$index_fitting_num_atoms = $1;
			}

			if ( $index_num_atoms < $index_fitting_num_atoms ) {

				my $response = $top_fit_index -> messageBox( -message => "Number of atoms selected for fitting is greater than the number of atoms selected for the creation of the dcd file. Please evaluate your atmid/segid/resid selection and resubmit.",
															 -type => 'ok',
															 -icon => 'warning', );
			}
			else {

				foreach ( @index_seg_ids ) {

					if ( defined ( $_ ) ) {

						$index_seg_id_flag = $index_seg_id_flag . $_;
					}
				}

				if ( $seg_id_flag ) {

					$flag = " -w -v -fit -index $ref_index $ref_index_atom_num $no_fit_index $index_atm_id_flag $res_id_flag $custom_id_flag $index_seg_id_flag $dcd_file $psf_file";
				}
				else {

					$flag = " -w -v -fit -index $ref_index $ref_index_atom_num $no_fit_index $index_atm_id_flag $res_id_flag $custom_id_flag $dcd_file $psf_file";
				}

				$text -> insert( 'end', "\nNow performing selective fitting. ", 'valid', );
				$text -> see( 'end', );
				$mw -> update;

				&carma;
				if ( $all_done ) {

					$text -> insert( 'end', "Fitting complete\n", 'valid' );
					$text -> see( 'end', );

					my $next_response = $top_fit_index -> messageBox( -message => "Would you like to use this PSF - DCD pair in other calculations?",
																	  -type => 'yesno',
																	  -icon => 'question', );

					if( $next_response eq "Yes" ) {

						$dcd_count++;
						$active_dcd_label -> configure( -text => "Active .dcd: carma_fitted_$dcd_count.dcd", );
						$active_psf_label -> configure( -text => "Active .psf: carma_fitted_$dcd_count.psf", );
						if ( $^O eq 'linux' ) {

							`mv carma.fitted.dcd carma_fitted_$dcd_count.dcd`;
							`mv carma.selected_atoms.psf carma_fitted_$dcd_count.psf`;
						}
						else {

							`move carma.fitted.dcd carma_fitted_$dcd_count.dcd`;
							`move carma.selected_atoms.psf carma_fitted_$dcd_count.psf`;
						}

						$top_fit_index -> withdraw;
					}
					else {

						$frame_fit_index1 -> messageBox( -type => "ok",
														 -message => "These files will not be used in any calculations and will be overwritten next time you perform a fitting", );

						$top_fit_index -> withdraw;
					}
				}
				else {

					$top_fit_index -> withdraw;
					$text -> insert( 'end' , "Something went wrong\nCheck carma.out.copy for details\n", 'error' );
					$text -> see( 'end', );
				}
			}
		}, )
		-> pack( -side => 'right', );
	}
	else {

		$top_fit_index -> deiconify;
		$top_fit_index -> raise;
	}
}

###################################################################################################
###   Create a subfolder in the CWD for the result files                                        ###
###################################################################################################

sub create_dir {

	# If the string returned by the getcwd #
	# function contains the name of the    #
	# folder used for storing the results  #
	# of the program then terminate the    #
	# subroutine with a success status     #
	if ( getcwd =~ /carma_temp/ ) {

		return(0);
	}

	# If the folder does not exist in the  #
	# CWD it is created and a subfolder    #
	# with the current time as it's name   #
	# will be created as well. This folder #
	# will serve as the storing point for  #
	# every grcarma session                #
	if (! -d "carma_results" ) {

		mkdir "carma_results", 0755;
		mkdir "carma_results/$timeStamp", 0755;
		chdir ( "carma_results/$timeStamp" );
	}
	# If the folder exists then only the   #
	# subfolder of every session is made   #
	else {

		mkdir "carma_results/$timeStamp", 0755;
		chdir ( "carma_results/$timeStamp" );
	}

	# After the folder(s) have been made   #
	# they are made the CWD and link to    #
	# specified .psf and .dcd files are    #
	# created                              #
	if ( $^O eq 'linux' ) {

		`ln -s $psf_file .`;
		`ln -s $dcd_file .`;
	}
	else {

		link ( $psf_file, "psf_file.psf", );
		link ( $dcd_file, "$dcd_name.dcd", );

		`copy ..\\..\\carma.exe .`;
	}
}

###################################################################################################
###   Create the atmid radiobutton bar                                                          ###
###################################################################################################

sub radiobuttons {

	$_[0] -> Label ( -text => 'Atmid Selection' ) -> pack;

	my @radiobuttons = ( 'CA', 'Backbone', 'Heavy', 'All atoms', 'Custom selection', );
	my @radio_b;

	# For every item of the radiobuttons   #
	# array draw a radiobutton named after #
	# each item and if the radiobutton is  #
	# active store it's name in a variable #
	for my $i ( 0 .. $#radiobuttons ) {

		$radio_b[$i] = $_[0] -> Radiobutton( -text => $radiobuttons[$i],
											 -value => $radiobuttons[$i],
											 -variable => \$atm_id,
											 -command => sub {

										# If the above variable equals any of  #
										# the @radiobuttons entries specify    #
										# atmid flags for each entry           #
										if ( $atm_id eq 'CA' ) {

											$atm_id_flag = "";
											$custom_id_flag = '';
											$custom_selection = 0;
										}
										elsif ( $atm_id eq 'Backbone' ) {

											$atm_id_flag = " -atmid C -atmid CA -atmid N -atmid O";
											$custom_id_flag = '';
											$custom_selection = 0;
										}
										elsif ( $atm_id eq 'Heavy' ) {

											$atm_id_flag = " -atmid HEAVY";
											$custom_id_flag = '';
											$custom_selection = 0;
										}
										elsif ( $atm_id eq 'All atoms' ) {

											$atm_id_flag = " -atmid ALLID";
											$custom_id_flag = '';
											$custom_selection = 0;
										}
										}, );
		if ( $_[0] eq $f2 ) {

			$radio_b[$i] -> pack( -anchor => 'w', );
		}
		else {

			$radio_b[$i] -> pack( -side => 'left', -anchor => 'w', );
		}
	}

	$radio_b[0] -> invoke();
	$radio_b[4] -> configure( -command => \&raise_custom_window);
}

###################################################################################################
###   Create the segid checkbutton bar                                                          ###
###################################################################################################

sub checkbuttons {

	if ( ( $dpca_frame_1 && $_[0] eq $dpca_frame_1 ) || ( $frame_sur2 && $_[0] eq $frame_sur2 ) ) {

		$_[0] -> Label( -text => 'At least one segid selection required' ) -> pack;
	}
	else {

		$_[0] -> Label( -text => 'Segid Selection' ) -> pack;
	}

	my @check_b;
	my $count = 0;

	for my $i ( 0 .. $#unique_chain_ids ) {

		$check_b[$i] = $_[0] -> Checkbutton( -text => $unique_chain_ids[$i],
											 -variable => \$seg_ids[$i],
											 -offvalue => '',
											 -onvalue => " -segid $unique_chain_ids[$i]",
											 -command => sub {

						 if ( $seg_ids[$i] ne '' ) {

							 $count++;
						 }
						 else {

							 $count--;
						 }

						 if ( $unique_chain_ids[$i] =~ /^[A-Z]$/ && $seg_ids[$i] ne '' ) {

							 $active_run_buttons = 1;
							 $dpca_run_button -> configure( -state => 'normal', ) if ( $dpca_run_button );
						 }
						 elsif ( $unique_chain_ids[$i] =~ /^[A-Z]$/ && $count < 1 ) {

							 $active_run_buttons = 0;
							 $dpca_run_button -> configure( -state => 'disabled', ) if ( $dpca_run_button );
						 }
						 }, );

		if ( $_[0] eq $f3 ) {

			$check_b[$i] -> pack( -anchor => 'w', );
		}
		else {

			$check_b[$i] -> pack( -side => 'left', -anchor => 'w', );
		}
	}
}

###################################################################################################
###   Create the resid radiobutton bar                                                          ###
###################################################################################################

sub otherbuttons {

	my @otherbuttons = ( 'All', 'Change', );
	my @other;

	$_[0] -> Label( -text => 'Resid Selection', ) -> pack;

	for my $i ( 0 .. $#otherbuttons ) {

		$other[$i] = $_[0] -> Radiobutton( -text => "$otherbuttons[$i]",
										   -value => $otherbuttons[$i], );

		if ( $_[0] eq $f4 ) {

			$other[$i] -> pack( -anchor => 'w', );
		}
		else {

			$other[$i] -> pack( -side => 'left', -anchor => 'w', );
		}
	}

	$other[0] -> configure( -command => sub {

		$res_id_flag = '';
		$have_custom_psf = 0;
		$f4_b -> destroy if ( $f4_b );
		if ( $dcd_count >= 0 ) {

			$active_psf_label -> configure( -text => "Active .psf: carma_fitted_$dcd_count.psf", );
		}
		else {

			$active_psf_label -> configure( -text => "Active .psf: $psf_file", );
		}
	}, );
	$other[1] -> configure( -command => \&resid_window, );
}
