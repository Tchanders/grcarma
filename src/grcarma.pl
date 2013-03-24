#!/usr/bin/perl

=head1 NAME

grcarma - GUI to molecular dynamics trajectories analysis program carma

=head1 SYNOPSIS

grcarma [ PSF FILE ] [ DCD FILE ]

grcarma.exe [ PSF FILE ] [ DCD FILE ]

=head1 DESCRIPTION

grcarma is a GUI to molecular dynamics trajectories analysis program
B<carma>. It is written in Perl and makes use of the Tk module for
graphics. It is available for Linux and Windows, and requires the
carma executable in the same folder ( or in the PATH ). As seen in
the synopsis the program can be launched with a .psf / .dcd pair of
files as arguments. Alternatively, the program can be run without any
arguments and the user will be prompted to specify the files to use
for the analyses, through a graphical interface.

=head1 AUTHOR

grcarma has been developed by Panagiotis Koukos, under the supervision
of L<Prof. Nicholas M. Glykos|http://utopia.duth.gr/~glykos/Carma.html>
at the L<Department of Molecular Biology and Genetics|http://mbg.duth.gr/index.en.shtml>
of L<Democritus University of Thrace|http://www.duth.gr/index.en.sxhtml>.

=head1 SEE ALSO

For more information, see L<https://github.com/pkoukos/grcarma>

=head1 LICENSE

Copyright (c) 2012, Panagiotis Koukos

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over

=item 1.

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

=item 2.

Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials
provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut

use strict;
use warnings;

# Use the Tk module for the GUI        #

use Tk;
use Tk::MsgBox;
require Tk::Chart::Lines if ( $^O eq 'MSWin32' );
require Tk::PlotDataset if ( $^O ne 'MSWin32' );
require Tk::LineGraphDataset if ( $^O ne 'MSWin32' );
require Tk::BrowseEntry;
require Tk::ROText;

# Import the following core modules    #

use Cwd;
use Cwd 'abs_path';
use File::Path 'mkpath';
use File::Copy 'cp', 'mv';

use List::MoreUtils 'uniq';

# Get the system time and modify it so #
# that it is human readable            #
# Find the OS type and store it in a   #
# variable                             #

my $launch_dir = getcwd;

my @now = localtime();
my $timeStamp = sprintf( "carma_results_%02d.%02d.%04d_%02d.%02d.%02d", $now[3], $now[4]+1, $now[5]+1900, $now[2], $now[1], $now[0] );

my ( $windows, $linux, $mac, ) = ( '', '', '', );

if ( $^O eq 'MSWin32' ) {

    $windows = 1;
}
elsif ( $^O eq 'linux' ) {

    $linux = 1;
}
elsif ( $^O eq 'darwin' ) {

    $mac = 1;
}

my $active_psf = '';
my $active_dcd = '';

# Declaration of the global scalars... #

our $VERSION = '0.1';

our $flag = '';
our $custom_id_flag = '';
our $seg_id_flag = '';
our $index_seg_id_flag = '';
our $custom_selection = '';
our $all_done = '';
our $num_atoms = '';
our $psf_button = '';
our $dcd_button = '';
our $have_psf = 0;
our $have_dcd = 0;
our $have_files = '';
our $filetypes = '';
our $have_custom_psf = '';
our $dcd_count = -1;
our $atm_id_flag = '';
our $res_id_flag = '';
our $header = '';
our $atm_id = '';
our $new_psf;
our $active_run_buttons = '';
our $active_run_buttons_qfract = '';
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
our $index_num_atoms = '';
our $dpca_frame = '';
our $dpca_frame_1 = '';
our $frame_sur2 = '';
our $cpca_frame = '';
our $cpca_frame_1 = '';
our $qfract_run_button;
our $phi_psi_run_button;
our $frame_qfract2;
our $frame_phi_psi1;

# and global arrays and hashes         #

our (

    @seg_ids,           @unique_chain_ids,      @unique_atom_types,
    @dropdown,          @amplitudes,            @dropdown_value,
    @upper_res_limit,   @lower_res_limit,       @upper_fit_limit,
    @lower_fit_limit,   @frame_res1,            @frame_fit_index4,
    %num_residues,      %substitutions,         @frame_fit6,
    @fit_drop,          @fit_drop_value,        @frame_fit_bars,
);

# If the OS is *nix/unix-like and the  #
# the folder "carma_results exists in  #
# the current working directory get    #
# it's size and store it in a scalar   #

my $wd_size = '';
my $wd_prefix = '';
my $ps_viewer = '';
my $pdb_viewer ='';
my $vmd = 0;
my $stride = 0;
my $weblogo = 0;
my $seqlogo = 0;
my $count = 0;

if ( $linux || $mac ) {

    # If any of the following programs #
    # is found in the /usr/bin folder  #
    # set it as the default .ps file   #
    # viewer                           #
    if ( `which evince` ) {

        $ps_viewer = "evince";
    }
    elsif ( `which gs` ) {

        $ps_viewer = "gs";
    }
    elsif ( `which display` ) {

        $ps_viewer = "display";
    }

    chomp $ps_viewer if ( $ps_viewer );

    if ( `which rasmol` ) {

        $pdb_viewer = 'rasmol';
    }
    elsif ( `which jmol` ) {

        $pdb_viewer = 'jmol';
    }
    elsif ( `which pymol` ) {

        $pdb_viewer = 'pymol';
    }

    chomp $pdb_viewer if ( $pdb_viewer );

    if ( `which vmd` ) {

        $vmd = 1;
    }
    if ( `which stride` ) {

        $stride = 1;
    }
    if ( `which weblogo` ) {

		$weblogo = 1;
	}
    elsif ( `which seqlogo` ) {

		$seqlogo = 1;
	}
}
# Do the same thing for windows        #
else {

    if ( -d "carma_results" ) {

        my $dir = `dir carma_results /s /-c | find "File(s)"`;

        if ( $dir !~ /\d* File...\s*(\d*)/ ) {

            $wd_size = int ( ( $1 / 1000000 ) + 0.5 ) . "MB";
        }
    }
}

# check for input from terminal        #
# if two files are specified           #
# and they are a DCD and a PSF file    #

my $run_from_terminal = 0;
my $psf_file = '';
my $dcd_file = '';
my $dcd_name = '';
my $psf_name = '';
my $dcd_loc = '';

if ( @ARGV ) {

    if ( @ARGV == 2 ) {

        # regardless of which was specified    #
        # first store each of them in a file   #
        # and store the name of the .dcd file  #
        # in a variable                        #
        if ( $ARGV[0] =~ /.*\.psf/ && $ARGV[1] =~ /.*\.dcd/ ) {

            $psf_file = abs_path( $ARGV[0] );
            $dcd_file = abs_path( $ARGV[1] );
            if ( $dcd_file =~ /(.*)(\/|\\)(\w*)\.dcd/ ) {

                $dcd_loc = $1;
                $dcd_name = $3;
                $active_dcd = $3 . '.dcd';
            }
            if ( $psf_file =~ /(.*)(\/|\\)(\w*)\.psf/ ) {

                $psf_name = $3;
                $active_psf = $3 . '.psf';
            }
        }
        elsif ( $ARGV[1] =~ /.*\.psf/ && $ARGV[0] =~ /.*\.dcd/ ) {

            $psf_file = abs_path( $ARGV[1] );
            $dcd_file = abs_path( $ARGV[0] );
            if ( $dcd_file =~ /(.*)(\/|\\)(\w*)\.dcd/ ) {

                $dcd_loc = $1;
                $dcd_name = $3;
                $active_dcd = $3 . '.dcd';
            }
            if ( $psf_file =~ /(.*)(\/|\\)(\w*)\.psf/ ) {

                $psf_name = $3;
                $active_psf = $3 . '.psf';
            }
        }
        # or terminate with a help message     #
        else {

            die "\nUsage: grcarma file.psf file.dcd\n\n";
        }

        # remember that files were specified   #
        # from STDIN and invoke the PSF parser #
        # subroutine                           #
        $run_from_terminal = 1;
        folder_size ( $launch_dir );
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
$mw -> protocol( 'WM_DELETE_WINDOW' => sub { kill -2, $$; } );

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

    my $x_position = int ( ( $mw -> screenwidth / 2 ) - ( $mw -> width / 2 ) );
    my $y_position = int ( ( ( $mw -> screenheight - 80 ) / 2 ) - ( $mw -> height / 2 ) );

    my $mw_position = "+" . $x_position . "+" . $y_position;

    #$mw -> geometry ("$mw_position");
    $mw -> focusForce if ( $^O ne 'linux' );
}

###################################################################################################
###   Container Frame                                                                           ###
###################################################################################################

# Create the first frame ( container ) #
my $f0 = $mw -> Frame();

# If files are specified from STDIN    #
# draw the container frame and proceed #
# normally                             #
unless ( $run_from_terminal ) {

    #~ $f0 -> pack( -side => 'top', -expand => 1, -fill => 'both', );
    $mw -> waitVariable(\$have_files);
    $mw -> update;
}

###################################################################################################
###   File Menu                                                                                 ###
###################################################################################################

# Create the menubar                   #
$mw -> configure( -menu => my $menubar = $mw -> Menu );

# Create the menubutton "File" and the #
# menubutton "Help"                    #
my $file = $menubar -> cascade( -label => '~File');
my $help = $menubar -> cascade( -label => '~Help');

# Draw a separating line               #
$file -> separator();

# Create a command of the "file" menu- #
# button which terminates the program  #
$file -> command( -label => "Exit",
                  -underline => 1,
                  -command => [ $mw => 'destroy' ], );
$help -> command( -label => 'About',
                  -command => \&about, );

###################################################################################################
###   Menubutton Frame                                                                          ###
###################################################################################################

my $font_12 = qw/-*-*-*-r-*-*-*-130-*-*-*-*-*-*/;
my $font_20 = qw/-*-*-*-r-*-*-*-200-*-*-*-*-*-*/;

# Draw the second frame ( menubuttons) #
# on top of the first one              #
my $f1 = $f0 -> Frame ( qw/ -relief raised -borderwidth 1/ ) -> pack ( qw/ -side left -expand 1 -fill both/ );

# ... the fitting menu                 #
my $fitting_menu = $f1 -> Button( -text => 'Fitting',
                                  -command => \&fit_window,
                                  -width => 24,
                                  -font => "$font_12", ) -> pack;

#Draw the button for the rmsd menu...  #
my $rmsd_menu = $f1 -> Button( -text => 'RMSD Matrix',
                               -command => \&rmsd_window,
                               -width => 24,
                               -font => "$font_12", ) -> pack;

# ... the dpca menu                    #
my $dpca_menu = $f1 -> Button( -text => 'Dihedral PCA',
                               -command => \&dpca_window,
                               -width => 24,
                               -font => "$font_12", ) -> pack;

# ... the cpca menu                    #
my $cpca_menu = $f1 -> Button( -text => 'Cartesian PCA',
                               -command => \&cpca_window,
                               -width => 24,
                               -font => "$font_12", ) -> pack;



# ... the eigen calculations menu      #
#~ my $eigen_menu = $f1 -> Button( -text => 'Eigen calculations',
                                #~ -command => \&eigen_window,
                                #~ -width => 24,
                                #~ -font => "$font_12", ) -> pack;

# ... the var_covar matrix menu        #
my $varcov_menu = $f1 -> Button( -text => "Covariance, average and\nrepresentative structures",
                                 -command => \&cov_avg_rep_window,
                                 -width => 24,
                                 -font => "$font_12", ) -> pack;

# ... the secondary structure menu     #
my $stride_menu;
if ( $linux or $mac ) {

    $stride_menu = $f1 -> Button( -text => "Secondary structure",
                                  -command => \&stride_window,
                                  -state => 'disabled',
                                  -width => 24,
                                  -font => "$font_12", ) -> pack;
}

#Draw the button for the qfract menu...#
my $qfract_menu = $f1 -> Button( -text => 'Fraction of native contacts',
                                 -command => \&qfract_window,
                                 -width => 24,
                                 -font => "$font_12", ) -> pack;

# ... the average distances menu      #
my $rms_menu = $f1 -> Button( -text => 'Distance maps',
                              -command => \&rms_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the gyration menu               #
my $rgr_menu = $f1 -> Button( -text => 'Radius of gyration',
                              -command => \&rgr_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the entropy menu                 #
my $entropy_menu = $f1 -> Button( -text => 'Entropy',
                                  -command => \&entropy_window,
                                  -width => 24,
                                  -font => "$font_12", ) -> pack;

# ... the pdb menu                    #
my $pdb_menu = $f1 -> Button( -text => 'Extract PDB(s)',
                              -command => \&pdb_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the surface area menu           #
my $sur_menu = $f1 -> Button( -text => 'Surface area',
                              -command => \&sur_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the map menu                    #
my $map_menu = $f1 -> Button( -text => 'Ion-water distribution',
                              -command => \&map_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the distances menu              #
my $dis_menu = $f1 -> Button( -text => 'Distances',
                              -command => \&dis_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the bending angles menu         #
my $ang_menu = $f1 -> Button( -text => 'Bending Angles',
                              -command => \&bnd_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the torsion angles menu         #
my $tor_menu = $f1 -> Button( -text => 'Torsion Angles ( general )',
                              -command => \&tor_window,
                              -width => 24,
                              -font => "$font_12", ) -> pack;

# ... the phi-psi angles menu         #
my $phi_psi_menu = $f1 -> Button( -text => 'phi/psi dihedral angles',
                                  -command => \&phi_psi_window,
                                  -width => 24,
                                  -font => "$font_12", ) -> pack;

# ... the index fitting menu           #
#~ my $_menu = $f1 -> Button( -text => "Average and representative\nstructures",
                                  #~ -command => \&avg_rep_window,
                                  #~ -width => 24,
                                  #~ -font => "$font_12", ) -> pack;

$f1 -> Label( -text => "\n", ) -> pack( -side => 'top', );

# ... the image menu                   #
our $image_menu = $f1 -> Button( -text => 'View Results',
                                 -command => [ \&image_window ],
                                 -width => 24,
                                 -font => "$font_12",
                                 -state => 'disabled', ) -> pack;

# and the exit menu                    #
my $exit_menu = $f1 -> Button( -text => 'EXIT',
                               -width => 24,
                               -command => \&exit,
                               -font => "$font_12", ) -> pack;

###################################################################################################
###   Atmid Frame                                                                               ###
###################################################################################################

# Draw the third frame (atmids) on top #
# of the first                         #
my $f2 = $f0 -> Frame( qw/ -borderwidth 1 -relief raised/ ) -> pack( qw/ -expand 1 -fill both/ );
&radiobuttons ( $f2 );

###################################################################################################
###   Segid Frame                                                                               ###
###################################################################################################

# Draw the fourth frame(segids) on top #
# of the first                         #
my $f3 = $f0 -> Frame( qw/ -borderwidth 1 -relief raised/ ) -> pack( qw/ -expand 1 -fill both/ );
&checkbuttons ( $f3 );

###################################################################################################
###   Resid Frame                                                                               ###
###################################################################################################

# Draw the fifth frame (resids) on top #
# of the first                         #
my $f4 = $f0 -> Frame( qw/ -borderwidth 1 -relief raised/ ) -> pack( qw/ -expand 1 -fill both/ );
&otherbuttons ( $f4 );

###################################################################################################
###   Textbox Frame                                                                             ###
###################################################################################################

# Draw the sixth frame(textbox) on top #
# of the first one and immediately     #
# after the fifth frame is drawn       #
my $f5 = $f0 -> Frame( qw/ -borderwidth 1 -relief raised/ )
                           -> pack( -after => $f1, -side => 'left', -fill => 'both', -expand => 1, );

our $text = $f5 -> Scrolled( "Text",
                         -bg => 'black',
                         -fg => 'white',
                         -font => "monospace 10 bold",
                         -wrap => 'char',
                         -scrollbars=> 'e',
                         -width => 75,
                         -height => 29, )
                         ->pack();

#~ $text -> configure( -height => 41, ) if ( $mac || $linux );
#~ $text -> configure( -width => 85, ) if ( $windows );

# Define three colored text tags       #
# to be used for the text displayed    #
# in the textbox                       #
$text -> tagConfigure( "error", -foreground => "red3" );
$text -> tagConfigure( "valid", -foreground => "green3" );
$text -> tagConfigure( "info", -foreground => "orange1" );

# Also tie the STDOUT to the textbox   #
tie *STDOUT, 'Tk::Text', $text -> Subwidget( 'scrolled' );

$text -> insert( 'end', "The size of carma_results folder is: $wd_size $wd_prefix\n", ) if ( ( $linux || $mac ) && $wd_size > 100 );

# If OS is *nix/unix-like insert a     #
# line informing the user of the prog  #
# selected for .ps viewing             #
if ( $linux || $mac  ) {

    if ( $ps_viewer ) {

        $text -> insert( 'end', "The program selected for .ps viewing is \"$ps_viewer\"\n", 'info' );
    }

    if ( $pdb_viewer ) {

        $text -> insert( 'end', "The program selected for .pdb viewing is \"$pdb_viewer\"\n", 'info' );
    }

    if ( $vmd ) {

        $text -> insert( 'end', "Found vmd in the PATH. Will include .cns map files in the results window\n", 'info' );
    }

    if ( $stride ) {

        $stride_menu -> configure( -state => 'normal', );
    }
    else {

        $text -> insert( 'end', "Secondary structure assignments have been turned-off because no 'stride' executable could be located in the PATH\n", 'info' );
    }
}

$text -> insert( 'end', "\nSELECT A TASK FROM THE LEFT PANEL\n" );

###################################################################################################
###   Active file frame                                                                         ###
###################################################################################################

# Draw the seventh frame(active files) #
# on top of the first one immediately  #
# after the fifth frame is drawn       #
my $f6 = $f0 -> Frame( qw/ -borderwidth 1 -relief raised/ )
                            -> pack( -after => $f1, -side => 'bottom', -fill => 'both', -expand => 1, );

# Create the labels displaying the     #
# active .psf & .dcd files and update  #
# the mainwindow to include them       #
our $active_psf_label = $f6 -> Label( -text => "Active .psf: $active_psf", -fg => 'blue', -font => "$font_20", )
                                      -> pack( -side => 'left', );
our $active_dcd_label = $f6 -> Label( -text => "Active .dcd: $active_dcd", -fg => 'blue', -font => "$font_20", )
                                      -> pack( -side => 'right', );

my $go_back_button = $f6 -> Button( -text => 'Go back to original psf/dcd', -state => 'disabled', -command => sub {

    $active_psf = $psf_name . '.psf';
    $active_dcd = $dcd_name . '.dcd';
    $active_psf_label -> configure( -text => "Active .psf: $active_psf", );
    $active_dcd_label -> configure( -text => "Active .dcd: $active_dcd", );
}, ) -> pack( -side => 'bottom', );

$f0 -> pack( -side => 'top', -fill => 'x', -expand => 1, );
$mw -> update();
$mw -> minsize ( $mw -> reqwidth, $mw -> reqheight ) if ( ( $mac || $linux ) && $mw );

# Get the resolution of the screen     #
# and position the mainwindow centered #
# and every other window to it's right #
my $x_position = int ( ( $mw -> screenwidth / 2 ) - ( $mw -> width / 2 ) );
my $y_position = int ( ( ( $mw -> screenheight - 80 ) / 2 ) - ( $mw -> height / 2 ) );

my $mw_position = "+" . $x_position . "+" . $y_position;#print $mw_position;
my $toplevel_position = "+" . ( $x_position + 150 ) . "+" . ( $y_position + 100 );

my $plot_step = ( $header / ( $mw -> screenwidth ) );

#$mw -> geometry ("$mw_position");
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

    if ( $linux || $mac ) {

        if ( $_[0] eq 'psf' ) {

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

        if ( $_[0] eq 'psf' ) {

            $filetypes = [ ['PSF FIles',  '.psf'], ['PSF FIles',  '.psf'] ];
        }
        elsif ( $_[0] eq 'dcd' ) {

            $filetypes = [ ['DCD Trajectory Files', '.dcd'], ['DCD Trajectory Files', '.dcd'] ];
        }
    }

    my $file = $mw -> getOpenFile( -filetypes => $filetypes, -initialdir => getcwd, );
    # If the file selected through the     #
    # getOpen method is a .psf file        #
    if ( $file =~ /(.*)(\/|\\)(\w*)\.psf/ ) {

        if ( $linux || $mac ) {

            # If on *nix invoke the abs_path       #
            # subroutine and store it's result in  #
            # a scalar. This is nessecary because  #
            # normally relative paths will be used #
            # rendering the data in $psf_file      #
            # obsolete every time the working      #
            # directory is changed                 #
            $psf_file = abs_path ( $file );
            $psf_name = $3;
            $active_psf = $3 . '.psf';
        }
        else {

            $psf_name = $3;
            $active_psf = $3 . '.psf';
            # else substitute the '/' for '\' in   #
            # $file as windows uses a backward     #
            # slash & the getOpen method returns   #
            # the absolute path to the file unix-  #
            # style                                #
            $file =~ s/\//\\/g;
            $psf_file = $file;
        }
        $have_psf = 1;
    }
    # Do the same for .dcd files and add a #
    # scalar which contains the the name   #
    # of the dcd file                      #
    elsif ( $file =~ /(.*)\/(\w*)\.dcd/ ) {

        if ( $linux || $mac ) {

            $dcd_file = abs_path ( $file );
            $dcd_loc = $1;
            $dcd_name = $2;
            $active_dcd = $2 . '.dcd';
        }
        else {

            $dcd_loc = $1;
            $dcd_name = $2;
            $active_dcd = $2 . '.dcd';
            $file =~ s/\//\\/g;
            $dcd_loc =~ s/\//\\/g;
            $dcd_file = $file;
        }
        $have_dcd = 1;
        folder_size ( $launch_dir );
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

    if ( $have_psf && $have_dcd ) {

        &parser;

        $have_psf = 0;
        $have_dcd = 0;
    }
}

###################################################################################################
###   Parse the .psf file to extract info for the protein(s)                                    ###
###################################################################################################

sub parser {

    open PSF_FILE, '<', $psf_file || die "Cannot open $psf_file for reading: $!\n";

    # Extract the number of atoms found    #
    # in the .psf file                     #
    $num_atoms = 0;
    my $psf_line;
    my $psf_pos;
    #~ our $new_psf;

    while ( <PSF_FILE> ) {

        if ( /(\d*)\s\!NATOM/ ) {

            $num_atoms = $1;
            $psf_pos = tell;
            $psf_line = $.;
            last;
        }
    }

    my @psf_file = <PSF_FILE>;
    close PSF_FILE;

    my @test_line = split '', $psf_file[$psf_line];
    if ( $test_line[9] =~ / / ) {

        my $response;

        if ( $run_from_terminal ) {

            print "It seems the .psf file you specified lacks chain ids. If this is a single " .
                   "chain molecule-without waters and ions- you can assign chain id A to all " .
                   "atoms and procced normally. Do you want to do so now [Y/n]?";

            $response = <STDIN>;
        }
        else {

            $response = $mw -> messageBox( -message => "It seems the .psf file you specified " .
            "lacks chain ids. If this is a single chain molecule-without waters and ions- you can " .
            "assign chain id A to all atoms and procced normally. Do you want to do so now? Click " .
            "'no' to terminate the program, fix the .psf and resubmit.",
                               -icon => 'warning',
                               -type => 'yesno', );
        }

        if ( $response !~ /n/i ) {

            $new_psf = "$psf_name.mod.psf";

            open PSF_FILE, '<', $psf_file || die "Cannot open $psf_file for reading: $!\n";
            open NEW_PSF, '>', $new_psf || die "Cannot open $new_psf for reading: $!\n";

            my $line_count = 0;
            while ( <PSF_FILE> ) {

                if ( /\d*\s\!NATOM/ ) {

                    print NEW_PSF $_;
                    last;
                }
                else {

                    print NEW_PSF $_;
                }
            }

            while ( <PSF_FILE> ) {

                if ( $line_count < $num_atoms && /^(\s+\d+ ) (\s+.+?)$/ ) {

                    print NEW_PSF $1 . 'A' . $2 . "\n";
                }
                else {

                    print NEW_PSF $_;
                }

                $line_count++;
            }

            close NEW_PSF;
            close PSF_FILE;

            $psf_file = $new_psf;
            $active_psf = $new_psf;
        }
        else {

            if ( $run_from_terminal ) {

                die ($!);
            }
            else {

                $mw -> destroy;
                kill -9, $$ or die ($!);
            }
        }
    }

    open PSF_FILE, '<', $psf_file || die "Cannot open $psf_file for reading: $!\n";

    seek PSF_FILE, $psf_pos, 0;

    my $i = 0;
    my $j = 0;
    my $k = 0;

    my @atom_types;
    my @chain_ids;

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
    if ( $linux || $mac ) {

        $valid_psf_dcd_pair = `carma -v -fit -last 2 $psf_file $dcd_file`;
    }
    else {

        $valid_psf_dcd_pair = `carma.exe -v -fit -last 2 $psf_file $dcd_file`;
    }

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

                $mw -> destroy;
                kill -9, $$ || die ( $! );
            }
        }
    }
    elsif ( @unique_chain_ids >= 20 ) {

        if ( $run_from_terminal ) {

            die "\nIt seems that the .psf file lacks chain ids. Please fix this and retry.\n\n";
        }
        else {

            $mw -> messageBox ( -message => "It seems that the .psf file lacks chain ids. Please fix this and retry.",
                                -type => 'ok',
                                -icon => 'warning', );
            $mw -> destroy;
            kill -9, $$ || die ( $! );
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

    my $input;
    $input = shift if ( $_[0] and $_[0] ne 'dcd' );

    if ( $input ) {

        &create_dir;

        if ( $linux || $mac ) {

            `carma -v -fit -last 1 $active_psf $active_dcd > carma.out`;
        }
        else {

            `carma.exe -v -fit -last 1 $active_psf $active_dcd > carma.out`;
        }

    }
    else {

        if ( $linux || $mac ) {

            `carma -v -fit -last 1 $psf_file $dcd_file > carma.out`;
        }
        else {

            `carma.exe -v -fit -last 1 $psf_file $dcd_file > carma.out`;
        }
    }

    unlink ( "carma.fit-rms.dat", "carma.fitted.dcd" );

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

    if ( $input ) {

        return ( $header );
    }

    # At this point every check has been   #
    # succesful and unless the program was #
    # run from the terminal, the container #
    # frame is drawn and at the same time  #
    # the window for file selection is     #
    # withdrawn                            #
    unless ( $run_from_terminal ) {

        $gui -> destroy;
        $f0 -> pack( -side => 'top', -fill => 'both', -expand => 1, );
        $mw -> update;
        $have_files = 1;
        $run_from_terminal = 0;
    }

    $have_files = 1;
    $mw -> minsize ( $mw -> reqwidth, $mw -> reqheight ) if ( ( $mac || $linux ) && $mw );
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

    $all_done = 0;
    $flag =~ s/[\s]\s+/ /g;
    $flag = 'carma.exe' . $flag if ( $windows );
    $flag = 'carma' . $flag . " $active_psf $active_dcd" if ( $linux || $mac );

    if ( $windows ) {

        $text -> insert( 'end', " Running carma with the flag :\n", 'valid' );
        $text -> insert( 'end', "$flag\n", 'info' );
        $text -> see( 'end', );
        $mw -> update;

        system ( "$flag $active_psf $active_dcd > carma.out.copy" );
    }
    elsif ( $linux ) {

        $text -> insert( 'end', "$flag\n", 'info' );
        $text -> see( 'end', );
        $mw -> update;

        system ( "xterm -fg white -bg black -geometry 80x25+800+200 -e \"$flag $active_psf $active_dcd | tee carma.out.copy\"" );
    }
    elsif ( $mac ) {

        $text -> insert( 'end', "Running carma with the flag :\n", 'valid' );
        $text -> insert( 'end', "$flag\n", 'info' );
        $text -> see( 'end', );
        $mw -> update;

        system ( "$flag $active_psf $active_dcd | tee carma.out.copy" );
    }

    # When the run is completed open the   #
    # file 'carma.out.copy' in the CWD and #
    # parse through it one line at a time  #
    # searching for the pattern 'All done' #
    open TEMP_OUT, "carma.out.copy" || die "Cannot open carma.out.copy for reading: $!\n";
    while ( <TEMP_OUT> ) {

        # If a match is found set the value of #
        # $all_done to 1                       #
        if ( /All done/i ) {

            $all_done = 1;
        }
        else {

            $all_done = 0;
        }
    }

    close TEMP_OUT;

    $flag = '';
    $index_seg_id_flag = '';
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

    $custom_id_flag = '';
    $custom_selection = '';

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

    my $rmsd_first = 1;
    my $rmsd_first_flag = '';
    my $rmsd_last = dcd_header_parser( "rmsd" );
    my $rmsd_last_flag = '';
    my $rmsd_step;
    my $rmsd_step_flag = '';
    my $rmsd_min = '';
    my $rmsd_min_flag = '';
    my $rmsd_max = '';
    my $rmsd_max_flag = '';
    my $rmsd_reverse = '';
    my $rmsd_plot = '';
    my $rmsd_top;

    if ( !Exists( $rmsd_top ) ) {

        # If the number or frames is greater   #
        # than 3k set the value of $rmsd_step  #
        # to $header/3000 rounded up to the    #
        # nearest integer, otherwise set it to #
        # 1                                    #
        if ( $rmsd_last <= 3000 ) {

            $rmsd_step = 1;
        }
        elsif ( $rmsd_last > 3000 ) {

            $rmsd_step = int ( ( $rmsd_last / 3000 ) + 0.5 );
        }

        $rmsd_top = $mw -> Toplevel( -title => 'RMSD matrix' );
        $rmsd_top -> geometry("$toplevel_position");

        my $frame_rmsd1 = $rmsd_top -> Frame() -> pack( -expand => 1, -fill => 'x', );
        our $frame_rmsd2 = $rmsd_top -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_rmsd3 = $rmsd_top -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_rmsd4 = $rmsd_top -> Frame() -> pack( -expand => 1, -fill => 'x', );

        radiobuttons ( $frame_rmsd1 );
        checkbuttons ( $frame_rmsd2 );
        otherbuttons ( $frame_rmsd3 );

        $frame_rmsd4 -> Label( -text => "\n", ) -> grid ( -row => 0, -column => 0, );

        # Create entry boxes for user input    #
        $frame_rmsd4 -> Label( -text => 'First frame to use: ', )
                               -> grid( -row => 1, -column => 1, );
        $frame_rmsd4 -> Entry( -textvariable => \$rmsd_first, )
                               -> grid( -row => 1, -column => 2, );
        $frame_rmsd4 -> Label( -text => 'Last frame to use: ', )
                               -> grid( -row => 2, -column => 1, );
        $frame_rmsd4 -> Entry( -textvariable => \$rmsd_last, )
                               -> grid( -row => 2, -column => 2, );
        $frame_rmsd4 -> Label( -text => 'Stride (step) between frames: ', )
                               -> grid( -row => 3, -column => 1, );
        $frame_rmsd4 -> Entry( -textvariable => \$rmsd_step, )
                               -> grid( -row => 3, -column => 2, );

        $frame_rmsd4 -> Label( -text => 'Minimum value for postscript plot (dark blue): ', )
                               -> grid( -row => 1, -column => 3, );
        $frame_rmsd4 -> Entry( -textvariable => \$rmsd_min, )
                               -> grid( -row => 1, -column => 4, );
        $frame_rmsd4 -> Label( -text => 'Maximum value for postscript plot (dark red): ', )
                               -> grid( -row => 2, -column => 3, );
        $frame_rmsd4 -> Entry( -textvariable => \$rmsd_max, )
                               -> grid( -row => 2, -column => 4, );

        $frame_rmsd4 -> Checkbutton( -text => 'Reverse color gradient',
                                     -variable => \$rmsd_reverse,
                                     -offvalue => '',
                                     -onvalue => " -reverse", )
                                     -> grid( -row => 3, -column => 3, );

        my $frame_rmsd5 = $rmsd_top -> Frame() -> pack();

        # For every variable used for input that is active create a flag and add
        # it to the flag used to run carma
        $frame_rmsd5 -> Button( -text => 'Run',
                                -command => sub {

            $rmsd_first_flag = ( ( $rmsd_first != 1 ) ? " -first $rmsd_first" : '' );
            $rmsd_last_flag = ( ( $rmsd_last != $header ) ? " -last $rmsd_last" : '' );
            $rmsd_step_flag = ( ( $rmsd_step != 1 ) ? " -step $rmsd_step" : '' );
            $rmsd_min_flag = ( $rmsd_min ? " -min $rmsd_min" : '' );
            $rmsd_max_flag = ( $rmsd_max ? " -max $rmsd_max" : '' );

            $rmsd_top -> destroy();
            $mw -> update;

            # If a segid has been specified add it to the flag as well

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            if ( $seg_id_flag ) {

                $flag = " -v -w -cross $rmsd_first_flag $rmsd_last_flag $rmsd_step_flag $rmsd_min_flag $rmsd_max_flag $seg_id_flag $atm_id_flag $custom_id_flag $res_id_flag";
            }
            else {

                $flag = " -v -w -cross $rmsd_first_flag $rmsd_last_flag $rmsd_step_flag $rmsd_min_flag $rmsd_max_flag $atm_id_flag $custom_id_flag $res_id_flag";
            }
            &create_dir;

            $text -> insert( 'end', "\nNow calculating RMSD matrix. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma;

            if ( $all_done ) {

                $text -> insert( 'end', "Calculation finished. Now creating a postcript plot of carma.RMSD.matrix", 'valid' );
                $text -> see( 'end', );

                $mw -> update;
                sleep 1;

                my $coloring;
                $coloring = `carma.exe $rmsd_reverse -col - < carma.RMSD.matrix` if ( $windows );
                $coloring = `carma $rmsd_reverse -col - < carma.RMSD.matrix` if ( $linux || $mac );

                if ( $coloring =~ /(-?\d*)\.(\d*) to (-?\d*)\.(\d*)/ ) {

                    $text -> insert( 'end', "\nPlotted .ps image from $1.$2 to $3.$4\n", 'valid' );
                    $text -> insert( 'end', "Use \"View Results\"\n", 'valid' );
                    $text -> see( 'end', );
                    $image_menu -> configure( -state => 'normal', );
                    mv ( "carma.stdin.ps", "carma.RMSD_matrix.ps" );
                }
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
            }, )
            -> grid( -row => 2, -column => 2, );

        $frame_rmsd5 -> Button( -text => 'Return',
                                -command => [ $rmsd_top => 'withdraw' ], )
                                -> grid( -row => 2, -column => 1, );

    }
    else {

        $rmsd_top -> deiconify;
        $rmsd_top -> raise;
    }

}

###################################################################################################
###   Draw the window for the native contact calculation                                        ###
###################################################################################################

sub qfract_window {

    my $qfract_cutoff = 8;
    my $qfract_dist = 2;
    my $qfract_plot = '';
    my $qfract_ref = '';
    my $qfract_nat = '';
    my $qfract_ref_num = '';
    my $top_qfract;
    my $nat_pdb_file = '';
    my $nat_button = '';

    if ( !Exists ( $top_qfract ) ) {

        $top_qfract = $mw -> Toplevel( -title => 'Native Contacts', );
        $top_qfract -> geometry("$toplevel_position");
        $top_qfract -> protocol( 'WM_DELETE_WINDOW' => sub { $top_qfract -> withdraw }, );

        my $frame_qfract1 = $top_qfract -> Frame() -> pack( -expand => 1, -fill => 'x', );
        $frame_qfract2 = $top_qfract -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_qfract3 = $top_qfract -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_qfract4 = $top_qfract -> Frame() -> pack( -fill => 'x', );
        my $frame_qfract5 = $top_qfract -> Frame( -relief => 'groove', -borderwidth => 3, ) -> pack( -expand => 1, -fill => 'x', );

        $frame_qfract5 -> Label( -text => 'Distance Cutoff: ', )
                                 -> grid( -row => 1, -column => 1, );
        $frame_qfract5 -> Entry( -textvariable => \$qfract_cutoff, )
                                 -> grid( -row => 1, -column => 2, );
        $frame_qfract5 -> Label( -text => 'Residue Separation: ', )
                                 -> grid( -row => 2, -column => 1, );
        $frame_qfract5 -> Entry( -textvariable => \$qfract_dist, )
                                 -> grid( -row => 2, -column => 2, );

        &radiobuttons ( $frame_qfract1 );
        &checkbuttons ( $frame_qfract2 );
        &otherbuttons ( $frame_qfract3 );

        $frame_qfract4 -> Label( -text => 'Various Options' ) -> pack;

        $frame_qfract4 -> Checkbutton( -text => 'Automatically create a plot of the results file',
                                       -variable => \$qfract_plot,
                                       -offvalue => 0,
                                       -onvalue => 1, )
                                       -> pack( -anchor => 'w', );
        $nat_button = $frame_qfract4 -> Checkbutton( -text => 'Use pdb file to define the native structure',
                                                     -variable => \$qfract_nat,
                                                     -offvalue => '',
                                                     -onvalue => ' -nat',
                                                     -command => sub {

            $nat_pdb_file = $top_qfract -> getOpenFile( -filetypes => [ [ 'Native structure PDB file', '.pdb' ] ], );
            unless ( $nat_pdb_file ) {

                $nat_button -> toggle;
            }
        }, )
        -> pack( -anchor => 'w', );

        $frame_qfract4 -> Checkbutton( -text => 'Use frame ',
                                       -variable => \$qfract_ref,
                                       -offvalue => '',
                                       -onvalue => ' -ref', )
                                       -> pack( -side => 'left', -anchor => 'n', );
        $frame_qfract4 -> Entry( -textvariable => \$qfract_ref_num, )
                                 -> pack( -side => 'left', -anchor => 'n', );
        $frame_qfract4 -> Label( -text => 'as the native structure', )
                                 -> pack( -side => 'left', -anchor => 'n', );

        $frame_qfract5 -> Button( -text => 'Return',
                                  -command => [ $top_qfract => 'withdraw' ], )
                                  -> grid( -row => 3, -column => 1, );

        $qfract_run_button = $frame_qfract5 -> Button( -text => 'Run',
                                                       -state => 'disabled',
                                                       -command => sub {

            $top_qfract -> withdraw;

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            if ( $seg_id_flag ) {

                $flag = " -v -qf $qfract_cutoff $qfract_dist $qfract_nat $nat_pdb_file $qfract_ref $qfract_ref_num $atm_id_flag $seg_id_flag $res_id_flag";
            }
            else {

                $flag = " -v -qf $qfract_cutoff $qfract_dist $qfract_nat $nat_pdb_file $qfract_ref $qfract_ref_num $atm_id_flag $res_id_flag";
            }

            &create_dir;

            $text -> insert( 'end', "\nNow calculating qfract. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma;

            if ( $all_done ) {

                $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
                $text -> see( 'end', );
                $image_menu -> configure( -state => 'normal', );

                if ( $qfract_plot && -e "carma.Qfraction.dat" ) {

                    plot ( 'carma.Qfraction.dat' );
                    $qfract_plot = 0;
                }
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
        }, )
        -> grid( -row => 3, -column => 2, );

    if ( $active_run_buttons_qfract ) {

        $qfract_run_button -> configure( -state => 'normal', );
    }
    else {

        $qfract_run_button -> configure( -state => 'disabled', );
    }

    }
    else {

        $top_qfract -> deiconify;
        $top_qfract -> raise;
    }
}

###################################################################################################
###   Draw the window for the dPCA calculation                                                  ###
###################################################################################################

sub dpca_window {

    my $dpca_top;
    my $dpca_eigenvectors = '';
    my $dpca_combinations = '';
    my $dpca_temp = '';
    my $dpca_cutoff = '';
    my $dpca_dgwidth = '';
    my $dpca_dgwidth_num = '';
    my $dpca_3d = '';
    my $dpca_first = 1;
    my $dpca_first_flag = '';
    my $dpca_last = dcd_header_parser( "dpca" );
    my $dpca_last_flag = '';
    my $dpca_step = 1;
    my $dpca_step_flag = '';
    our $chi1 = '';
    our $include_segid = '';
    our $dpca_auto_entry;
    our $dpca_auto_entry_num = 10;

    our $res_id_flag;
    our @cluster_stats = '';

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
        $dpca_frame -> Label( -text => 'Total principal components to calculate: ',
                              -anchor => 'e',)
                              -> grid( -row => 2, -column => 1, -sticky => 'w', );
        $dpca_frame -> Entry( -textvariable => \$dpca_eigenvectors,)
                              -> grid( -row => 2, -column => 3, );
        $dpca_frame -> Label( -text => 'Number of components to use in PC(i)-PC(j) plots: ',
                              -anchor => 'e', )
                              -> grid( -row => 3, -column => 1, -sticky => 'w', );
        $dpca_frame -> Entry( -textvariable => \$dpca_combinations,)
                              -> grid( -row => 3, -column => 3, );
        $dpca_frame -> Label( -text => "Sigma cutoff ( automatically determined if left undefined ): ",
                              -anchor => 'e',)
                              -> grid( -row => 4, -column => 1, -sticky => 'w', );
        $dpca_frame -> Entry( -textvariable => \$dpca_cutoff,)
                              -> grid( -row => 4, -column => 3, );
        $dpca_frame -> Label( -text => 'First frame to use: ',
                              -anchor => 'w', )
                              -> grid( -row => 5, -column => 1, -sticky => 'w',);
        $dpca_frame -> Entry( -textvariable => \$dpca_first, )
                              -> grid( -row => 5, -column => 3, );
        $dpca_frame -> Label( -text => 'Last frame to use: ',
                              -anchor => 'w', )
                              -> grid( -row => 6, -column => 1, -sticky => 'w',);
        $dpca_frame -> Entry( -textvariable => \$dpca_last, )
                              -> grid( -row => 6, -column => 3, );
        $dpca_frame -> Label( -text => 'Stride (step) between frames: ',
                              -anchor => 'w', )
                              -> grid( -row => 7, -column => 1, -sticky => 'w',);
        $dpca_frame -> Entry( -textvariable => \$dpca_step, )
                              -> grid( -row => 7, -column => 3, );

        $dpca_frame -> Checkbutton( -text => 'Set limits for PC(i)-PC(j) plots: ',
                                    -anchor => 'e',
                                    -variable => \$dpca_dgwidth,
                                    -onvalue => " -dgwidth",
                                    -offvalue => '', )
                                    -> grid( -row => 8, -column => 1, -sticky => 'w', );
        $dpca_frame -> Entry( -textvariable => \$dpca_dgwidth_num,)
                              -> grid( -row => 8, -column => 3, );

        #~ $dpca_frame -> Label( -text => "For dPCA your atom type selection will be ignored.", )
                              #~ -> grid( -row => 9, -column => 2, );

        $dpca_frame ->Button( -text => 'Return',
                              -command => sub {

                                $dpca_top -> withdraw;
                                }, )
                              -> grid ( -row => 10, -column => 1, );

        $dpca_run_button = $dpca_frame ->Button( -text => 'Run',
                                                 -command => sub {

            $dpca_first_flag = ( ( $dpca_first != 1 ) ? " -first $dpca_first" : '' );
            $dpca_last_flag = ( ( $dpca_last != $header ) ? " -last $dpca_last" : '' );
            $dpca_step_flag = ( ( $dpca_step != 1 ) ? " -step $dpca_step" : '' );

            $dpca_top -> withdraw;

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            if ( $res_id_flag ) {

                if ( $dpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                    my $response = $mw -> messageBox( -message => 'You have specified a resid selection. Would you ' .
                                                                  'like the output .pdb files to include all atoms ?',
                                                      -type => 'yesno',
                                                      -icon => 'question', );

                    if ( $response =~ /yes/i ) {

                        $include_segid = 1;
                    }
                    else {

                        $include_segid = 0;
                        $seg_id_flag = '';
                    }

                    $flag = " -v -w -col $dpca_first_flag $dpca_last_flag $dpca_step_flag $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
                }
                elsif ( $seg_id_flag ) {

                    my $response = $mw -> messageBox( -message => 'You have specified a resid selection. Would you ' .
                                                                  'like the principal component analysis to include' .
                                                                  ' all atoms ?',
                                                      -type => 'yesno',
                                                      -icon => 'question', );

                    if ( $response =~ /yes/i ) {

                        $flag = " -v -w -col $dpca_first_flag $dpca_last_flag $dpca_step_flag $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag $seg_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
                    }
                    else {

                        $flag = " -v -w -col $dpca_first_flag $dpca_last_flag $dpca_step_flag $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
                    }
                }
                else {

                    $flag = " -v -w -col $dpca_first_flag $dpca_last_flag $dpca_step_flag $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $res_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
                }
            }
            else {

                $flag = " -v -w -col $dpca_first_flag $dpca_last_flag $dpca_step_flag $dpca_3d $dpca_dgwidth $dpca_dgwidth_num $chi1 $seg_id_flag -dPCA $dpca_eigenvectors $dpca_combinations $dpca_temp $dpca_cutoff";
            }

            &create_dir;
            if ( $dpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                opendir CWD, getcwd || die "Cannot open " . getcwd . ": $!";
                while ( my $dh = readdir CWD ) {

                    if ( $dh =~ /carma\.dPCA\.cluster_01.dcd/ ) {

                        my $response = $dpca_top -> messageBox( -message => 'The analysis you are about to perform will produce files ' .
                                                                            'that already exist in the working directory. Would you like to' .
                                                                            ' delete the old files before proceeding ?',
                                                                -icon => 'question',
                                                                -type => 'yesno', );
                        if ( $response =~ /yes/i ) {

                            unlink <*dPCA*>;
                        }
                    }
                }
                closedir CWD;
            }

            $text -> insert( 'end', "\nNow performing dPCA. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma ( "pca" );
            if ( $all_done ) {

                unless ( $dpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                    $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
                    $text -> see( 'end', );
                    $image_menu -> configure( -state => 'normal', );
                    $all_done = '';
                }

				if ( $dpca_auto_entry -> cget( -state, ) eq 'normal' ) {

					mv ( "carma.variance_explained.dat", "dPCA.variance_explained.dat" );
					if ( -f "carma.3d_landscape.cns" ) {

						mv ( "carma.3d_landscape.cns", "dPCA.3d_landscape.cns" );
					}

					opendir CWD, getcwd || die "Cannot open " . getcwd . ": $!";
					while ( my $dh = readdir CWD ) {

						if ( $dh =~ /carma.dPCA.DG_(\d+)_(\d+).(\w+)/ ) {

							mv ( "$dh", "dPCA.PC$1_vs_$2.$3" );
						}
						elsif ( $dh =~ /\w+.dcd.dPCA.varcov.(\w+)/ ) {

							mv ( "$dh", "dPCA.covariance.$1" );
						}
					}
					closedir CWD;

					auto_window ( 'dPCA' ) ;

					if ( $all_done ) {

						foreach ( @cluster_stats ) {

							$text -> insert( 'end', "$_\n", 'info' );
							$text -> see( 'end', );
						}

                        $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
                        $text -> see( 'end', );
                        $image_menu -> configure( -state => 'normal', );
                        $all_done = '';
					}
					else {

						$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
						$text -> insert( 'end', getcwd . "\n", 'info', );
						$text -> see( 'end', );
					}
				}
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
            }, )
        -> grid( -row => 10, -column => 3, );

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
        $dpca_frame_4 -> Checkbutton( -text => 'Include chi1 angles in the analysis',
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
    my $cpca_first = 1;
    my $cpca_first_flag = '';
    my $cpca_last = dcd_header_parser( "cpca" );
    my $cpca_last_flag = '';
    my $cpca_step = 1;
    my $cpca_step_flag = '';
    my $cpca_3d = '';
    my $chi1 = '';
    my $cpca_mass = '';
    my $cpca_use = '';
    my $cpca_top;
    our $include_segid;
    our $cpca_auto_entry;
    our $cpca_auto_entry_num = 10;
    our @cluster_stats = '';

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

        $cpca_frame -> Label( -text => 'Total principal components to calculate: ',
                              -anchor => 'e',)
                              -> grid( -row => 2, -column => 1, -sticky => 'w', );
        $cpca_frame -> Entry( -textvariable => \$cpca_eigenvectors,)
                              -> grid( -row => 2, -column => 3, );
        $cpca_frame -> Label( -text => 'Number of components to use in PC(i)-PC(j) plots: ',
                              -anchor => 'e',)
                              -> grid( -row => 3, -column => 1, -sticky => 'w', );
        $cpca_frame -> Entry( -textvariable => \$cpca_combinations,)
                              -> grid( -row => 3, -column => 3, );
        $cpca_frame -> Label( -text => 'Sigma cutoff ( automatically determined if left undefined ): ',
                              -anchor => 'e',)
                              -> grid( -row => 4, -column => 1, -sticky => 'w', );
        $cpca_frame -> Entry( -textvariable => \$cpca_cutoff,)
                              -> grid( -row => 4, -column => 3, );
        $cpca_frame -> Label( -text => 'First frame to use: ', )
                              -> grid( -row => 5, -column => 1, -sticky => 'w',);
        $cpca_frame -> Entry( -textvariable => \$cpca_first, )
                              -> grid( -row => 5, -column => 3, );
        $cpca_frame -> Label( -text => 'Last frame to use: ', )
                              -> grid( -row => 6, -column => 1, -sticky => 'w',);
        $cpca_frame -> Entry( -textvariable => \$cpca_last, )
                              -> grid( -row => 6, -column => 3, );
        $cpca_frame -> Label( -text => 'Stride (step) between frames: ', )
                              -> grid( -row => 7, -column => 1, -sticky => 'w',);
        $cpca_frame -> Entry( -textvariable => \$cpca_step, )
                              -> grid( -row => 7, -column => 3, );
        $cpca_frame -> Checkbutton( -text => 'Set limits for PC(i)-PC(j) plots: ',
                                    -anchor => 'e',
                                    -variable => \$cpca_dgwidth,
                                    -onvalue => " -dgwidth",
                                    -offvalue => '', )
                                    -> grid( -row => 8, -column => 1, -sticky => 'w', );
        $cpca_frame -> Entry( -textvariable => \$cpca_dgwidth_num,)
                              -> grid( -row => 8, -column => 3, );

        $cpca_frame ->Button( -text => 'Return',
                              -command => sub {

                              $cpca_top -> withdraw;
                              }, )
                             -> grid( -row => 9, -column => 1 );

        $cpca_frame ->Button( -text => 'Run',
                              -command => sub {

            $cpca_first_flag = ( ( $cpca_first != 1 ) ? " -first $cpca_first" : '' );
            $cpca_last_flag = ( ( $cpca_last != $header ) ? " -last $cpca_last" : '' );
            $cpca_step_flag = ( ( $cpca_step != 1 ) ? " -step $cpca_step" : '' );

            $cpca_top -> withdraw;

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            if ( $res_id_flag ) {

                if ( $cpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                    my $response = $mw -> messageBox( -message => 'You have specified a resid selection. Would you ' .
                                                                  'like the output .pdb files to include all atoms ?',
                                                      -type => 'yesno',
                                                      -icon => 'question', );

                    if ( $response =~ /yes/i ) {

                        $include_segid = 1;
                    }
                    else {

                        $include_segid = 0;
                        $seg_id_flag = '';
                    }

                    $flag = " -v -w -col -cov $cpca_first_flag $cpca_last_flag $cpca_step_flag $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
                }
                elsif ( $seg_id_flag ) {

                    my $response = $mw -> messageBox( -message => 'You have specified a resid selection. Would you ' .
                                                                  'like the principal component analysis to include' .
                                                                  ' all atoms ?',
                                                      -type => 'yesno',
                                                      -icon => 'question', );

                    if ( $response =~ /yes/i ) {

                        $flag = " -v -w -col -cov $cpca_first_flag $cpca_last_flag $cpca_step_flag $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $seg_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
                    }
                    else {

                        $flag = " -v -w -col -cov $cpca_first_flag $cpca_last_flag $cpca_step_flag $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
                    }
                }
                else {

                    $flag = " -v -w -col -cov $cpca_first_flag $cpca_last_flag $cpca_step_flag $res_id_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
                }
            }
            else {

                $flag = " -v -w -col -cov $cpca_first_flag $cpca_last_flag $cpca_step_flag $cpca_dgwidth $cpca_dgwidth_num $atm_id_flag $seg_id_flag $custom_id_flag -eigen -proj $cpca_eigenvectors $cpca_combinations $cpca_temp $cpca_cutoff $cpca_mass $cpca_3d $cpca_use";
            }

            &create_dir;
            if ( $cpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                opendir CWD, getcwd || die "Cannot open " . getcwd . ": $!";
                while ( my $dh = readdir CWD ) {

                    if ( $dh =~ /carma\.cPCA\.cluster_01.dcd/ ) {

                        my $response = $cpca_top -> messageBox( -message => 'The analysis you are about to perform will produce files ' .
                                                                            'that already exist in the working directory. Would you like to' .
                                                                            ' delete the old files before proceeding ?',
                                                                -icon => 'question',
                                                                -type => 'yesno', );
                        if ( $response =~ /yes/i ) {

                            unlink <*cPCA*>;
                        }
                    }
                }
                closedir CWD;
            }

            $text -> insert( 'end', "\nNow performing cPCA. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma ( "pca" );


            if ( $all_done ) {

                unless ( $cpca_auto_entry -> cget( -state, ) eq 'normal' ) {

                    $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
                    $text -> see( 'end', );
                    $image_menu -> configure( -state => 'normal', );
                    $all_done = '';
                }

                if ( $cpca_auto_entry -> cget( -state, ) eq 'normal' ) {

					mv ( "carma.variance_explained.dat", "cPCA.variance_explained.dat" );
					if ( -f "carma.3d_landscape.cns" ) {

						mv ( "carma.3d_landscape.cns", "cPCA.3d_landscape.cns" );
					}

					opendir CWD, getcwd || die "Cannot open " . getcwd . ": $!";
					while ( my $dh = readdir CWD ) {

						if ( $dh =~ /carma.PCA.DG_(\d+)_(\d+).(\w+)/ ) {

							mv ( "$dh", "cPCA.PC$1_vs_$2.$3" );
						}
						elsif ( $dh =~ /\w+.dcd.varcov.(\w+)/ ) {

							mv ( "$dh", "cPCA.covariance.$1" );
						}
					}
					closedir CWD;

					auto_window ( 'cPCA' );
					if ( $all_done ) {

						foreach ( @cluster_stats ) {

							$text -> insert( 'end', "$_\n", 'info' );
							$text -> see( 'end', );
						}

                        $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
                        $text -> see( 'end', );
                        $image_menu -> configure( -state => 'normal', );
                        $all_done = '';
					}
					else {

						$text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
						$text -> insert( 'end', getcwd . "\n", 'info', );
						$text -> see( 'end', );
					}
                }
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
            }, )
        -> grid( -row => 9, -column => 3 );

        $cpca_frame_1 = $cpca_top -> Frame()->pack( -fill => 'x', );
        my $cpca_frame_2 = $cpca_top -> Frame()-> pack( -fill => 'x', );
        my $cpca_frame_3 = $cpca_top -> Frame()-> pack( -fill => 'x', );
        my $cpca_frame_5 = $cpca_top -> Frame()-> pack( -side => 'top', -expand => 1, -fill => 'x', );
        my $cpca_frame_4 = $cpca_top -> Frame()-> pack( -side => 'top', -expand => 1, -fill => 'x', );

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

        $cpca_frame_4 -> Checkbutton( -text => 'Use mass weighting',
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

	my $input = shift;

    our $dpca_auto_entry;
    our $dpca_auto_entry_num;
    our $cpca_auto_entry;
    our $cpca_auto_entry_num;

    our $chi1;
    our $include_segid;

    our @cluster_stats;
    my $cluster_number;
    my $cluster_size = 0;

	# The psf/dcd files that are in use at the time the subroutine is called
	# This is necessary because the active files will change several times
	# as the subroutine is executed, and they need to revert to the original
	# ones when it is done
    my ( $remember_psf, $remember_dcd, ) = ( $active_psf, $active_dcd, );

	# $clusters is the number of clusters the user defined in the dpca or cpca panels
	# @clusters is the number of clusters contained in the file 'clusters.dat'
    my $clusters;
    my @clusters;

    my $fit_check = 0;
    my $super_check = 0;

    &create_dir;

    open CLUSTERS, "carma.clusters.dat" || die "Cannot open carma.clusters.dat for reading: $!\n";

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

	# If the number of clusters the user desires the cluster analysis to
	# be performed on, exceeds that of the number of clusters detailed in
	# the file 'clusters.dat'
    if ( $input eq 'cPCA' && $clusters > $cpca_auto_entry_num ) {

        $clusters = $cpca_auto_entry_num;
    }
    elsif ( $input eq 'dPCA' && $clusters > $dpca_auto_entry_num ) {

        $clusters = $dpca_auto_entry_num;
    }

    for ( $i = 1 ; $i <= $clusters ; $i++ ) {

        open CLUSTERS, '<', "carma.clusters.dat" || die "Cannot open carma.clusters.dat for reading: $!\n";

        my $file = "C_0$i.dat";
        open OUT, '>', $file || die "Cannot open $file for writing\n: $!";

        while ( <CLUSTERS> ) {

            if ( /^(\s*\d*\s*)(\d*)(.*)/ ) {

                if ( $2 == $i ) {

                    print OUT "$1$2\n";
                    $cluster_size++;
                }
            }
        }

        close OUT;
        close CLUSTERS;

        $cluster_number = sprintf ( "%2d", $i, );
        $cluster_size = sprintf ( "%7d", $cluster_size, );
        push ( @cluster_stats, "Cluster $cluster_number comprises $cluster_size frames (out of $header)" );

        $cluster_size = 0;

        if ( $i == 1 ) {

            $text -> insert( 'end', "\nNow performing cluster extraction. Running carma with flag :", 'valid', );
            $text -> see( 'end', );
            $mw -> update;
        }

        if ( $linux || $mac ) {

            $text -> insert( 'end', "\ncarma -v -sort $file $remember_dcd\n", 'info', );
            $text -> see( 'end', );
            $mw -> update;

            `carma -v -sort $file $remember_dcd`;
            `mv carma.reordered.dcd carma.$input.cluster_0$i.dcd`;
        }
        else {

            $text -> insert( 'end', "\ncarma.exe -v -sort $file $remember_dcd\n", 'info', );
            $text -> see( 'end', );
            $mw -> update;

            `carma.exe -v -sort $file $remember_dcd`;
            `move carma.reordered.dcd carma.$input.cluster_0$i.dcd`;
        }

        my $backbone = 'C|CA|N|O';

        my (
             $seg_custom, $seg_atm, $seg, $res_custom, $res_atm,
             $res,        $custom,  $atm, $nothing,    $seg_res,
        );

        if ( $include_segid ) {

            my @selected_atoms = split ' -atmid ', $custom_id_flag if ( $custom_id_flag );
            shift @selected_atoms if ( @selected_atoms );

            my $line_count = 1;
            my $regex_var = '';

            {
                local $" = '|';
                if ( $input eq 'cPCA' ) {

                    if ( $custom_id_flag ) {

                        $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)(@selected_atoms)(\s+.*)};
                    }
                    elsif ( $atm_id_flag =~ /heavy/i ) {

                        $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)([^H].*)(\s+.*)};
                    }
                    elsif ( $atm_id_flag =~ /allid/i ) {

                        $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)(\w+)(\s+.*)};
                    }
                    else {

                        $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)};
                    }
                }
                else {

                    $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)} if ( $input eq 'dPCA' );
                }
            }

            open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
            open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

            while ( <PSF> ) {

                if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                    last;
                }
                elsif ( /$regex_var/i ) {

                    print OUT "$1$2$3$4$5$6\n";
                }
            }

            close OUT;
            close PSF;

            $active_dcd = "carma.$input.cluster_0$i.dcd";
            $active_psf = "selected_residues.psf";

            $flag = " -v -w -fit -index -atmid ALLID";

            &carma ( 'auto' );

            if ( $all_done ) {

                $seg_res = 1;
                $fit_check = 1;
            }
        }
        elsif ( $seg_id_flag ) {

            my @chains = split ' -segid ', $seg_id_flag;
            shift @chains;

            if ( $custom_id_flag ) {

                my @selected_atoms = split ' -atmid ', $custom_id_flag;
                shift @selected_atoms;

                my $line_count = 1;
                my $regex_var = '';

                {
                    local $" = '|';
                    $regex_var = qr{^(\s*\d+)(\s*)(@chains)(\s*\d+\s*\w+\s+)(@selected_atoms)(\s+.*)};
                }

                open PSF, '<', $psf_file || die "Cannot open $active_psf for reading: $!";
                open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

                while ( <PSF> ) {

                    if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                        last;
                    }
                    elsif ( /$regex_var/i ) {

                        print OUT "$1$2$3$4$5$6\n";
                    }
                }

                close OUT;
                close PSF;

                $active_dcd = "carma.$input.cluster_0$i.dcd";

                $flag = " -v -w -fit -index -atmid ALLID";

                &carma ( 'auto' );

                if ( $all_done ) {

                    $seg_custom = 1;
                    $fit_check = 1;
                }
            }
            elsif ( $atm_id_flag ) {

                my $heavy = 0;
                $heavy = 1 if ( $atm_id_flag =~ /HEAVY/ );
                my $allid = 0;
                $allid = 1 if ( $atm_id_flag =~ /ALLID/ );

                my $line_count = 1;
                my $regex_var = '';

                {
                    local $" = '|';
                    $regex_var = qr{^(\s*\d+)(\s*)(@chains)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)} if ( $atm_id =~ /backbone/i );
                    $regex_var = qr{^(\s*\d+)(\s*)(@chains)(\s*\d+\s*\w+\s+)(\w+)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );
                }

                open PSF, '<', $psf_file || die "Cannot open $active_psf for reading: $!";
                open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

                while ( <PSF> ) {

                    if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                        last;
                    }
                    elsif ( /$regex_var/i ) {

                        my $line = $1 . $2 . $3 . $4 . $5 . $6;

                        if ( $heavy && $5 !~ /^H/ ) {

                            print OUT "$line\n";
                        }
                        elsif ( $allid || $atm_id =~ /backbone/i ) {

                            printf OUT ( "%s\n", $line, );
                        }
                    }
                }

                close OUT;
                close PSF;

                $active_dcd = "carma.$input.cluster_0$i.dcd";

                $flag = " -v -w -fit -index -atmid ALLID";
                &carma ( 'auto' );

                if ( $all_done ) {

                    $seg_atm = 1;
                    $fit_check = 1;
                }

                $heavy = 0;
                $allid = 0;
            }
            else {

                my $line_count = 1;
                my $regex_var = '';

                {
                    local $" = '|';
                    $regex_var = qr{^(\s*\d+)(\s*)(@chains)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)};
                }

                open PSF, '<', $psf_file || die "Cannot open $active_psf for reading: $!";
                open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

                while ( <PSF> ) {

                    if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                        last;
                    }
                    elsif ( /$regex_var/i ) {

                        print OUT "$1$2$3$4$5$6\n";
                    }
                }

                close OUT;
                close PSF;

                $active_dcd = "carma.$input.cluster_0$i.dcd";

                $flag = " -v -w -fit -index -atmid ALLID";
                &carma ( 'auto' );

                if ( $all_done ) {

                    $seg = 1;
                    $fit_check = 1;
                }
            }
        }
        elsif ( $res_id_flag ) {

            if ( $custom_id_flag ) {

                #~ my @selected_atoms = split ' -atmid ', $custom_id_flag;
                #~ shift @selected_atoms;
#~
                #~ my $line_count = 1;
                #~ my $regex_var = '';
#~
                #~ {
                    #~ local $" = '|';
                    #~ $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)(@selected_atoms)(\s+.*)};
                #~ }
#~
                #~ open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
                #~ open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";
#~
                #~ while ( <PSF> ) {
#~
                    #~ if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {
#~
                        #~ last;
                    #~ }
                    #~ elsif ( /$regex_var/i ) {
#~
                        #~ print OUT "$1$2\n";
                    #~ }
                #~ }
#~
                #~ close PSF;
                #~ close OUT;

                $active_dcd = "carma.$input.cluster_0$i.dcd";
                $active_psf = "selected_residues.psf";

                if ( $input eq 'dPCA' ) {

                    $flag = " -v -w -fit $res_id_flag";
                }
                else {

                    $flag = " -v -w -fit $res_id_flag $custom_id_flag";
                }

                &carma ( 'auto' );

                if ( $all_done ) {

                    $res_custom = 1;
                    $fit_check = 1;
                }
            }
            elsif ( $atm_id_flag ) {

                #~ my $heavy = 0;
                #~ $heavy = 1 if ( $atm_id_flag =~ /HEAVY/ );
                #~ my $allid = 0;
                #~ $allid = 1 if ( $atm_id_flag =~ /ALLID/ );
#~
                #~ my $line_count = 1;
                #~ my $regex_var = '';
#~
                #~ $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)} if ( $atm_id =~ /backbone/i );
                #~ $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)(\w*)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );
#~
                #~ open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
                #~ open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";
#~
                #~ while ( <PSF> ) {
#~
                    #~ if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {
#~
                        #~ last;
                    #~ }
                    #~ elsif ( /$regex_var/i ) {
#~
                        #~ my $line = $1 . $2 . $3 . $4 . $5 . $6;
#~
                        #~ if ( $heavy && $5 !~ /^H/ ) {
#~
                            #~ print OUT "$line\n";
                        #~ }
                        #~ elsif ( $allid || $atm_id =~ /backbone/i ) {
#~
                            #~ printf OUT ( "%s\n", $line, );
                        #~ }
                    #~ }
                #~ }
#~
                #~ close OUT;
                #~ close PSF;

                $active_dcd = "carma.$input.cluster_0$i.dcd";
                $active_psf = "selected_residues.psf";

                if ( $input eq 'dPCA' ) {

                    $flag = " -v -w -fit $res_id_flag";
                }
                else {

                    $flag = " -v -w -fit $res_id_flag $atm_id_flag";
                }

                &carma ( 'auto' );

                if ( $all_done ) {

                    #~ if ( $linux or $mac ) {
#~
                        #~ if ( $input eq 'dpca' ) {
#~
                            #~ if ( $chi1 ) {
#~
                                #~ `carma -v -w -last 1 -atmid ALLID -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                            #~ }
                            #~ else {
#~
                                #~ `carma -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                            #~ }
                        #~ }
                        #~ else  {
#~
                            #~ `carma -v -w -last 1 $atm_id_flag -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                        #~ }
                    #~ }
                    #~ else {
#~
                        #~ if ( $input eq 'dpca' ) {
#~
                            #~ if ( $chi1 ) {
#~
                                #~ `carma.exe -v -w -last 1 -atmid ALLID -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                            #~ }
                            #~ else {
#~
                                #~ `carma.exe -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                            #~ }
                        #~ }
                        #~ else  {
#~
                            #~ `carma.exe -v -w -last 1 $atm_id_flag -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                        #~ }
                    #~ }
#~
                    #~ open IN, '<', "carma.selected_atoms.psf" or die "Cannot open carma.selected_atoms.psf for reading: $!\n";
                    #~ open OUT, '>', "new.selected_residues.psf" or die "Cannot open new.selected_residues.psf for writing: $!\n";
#~
                    #~ while ( <IN> ) {
#~
                        #~ print OUT $_;
                    #~ }
#~
                    #~ close ( OUT );
                    #~ close ( IN );
#~
                    #~ $active_psf = 'new.selected_residues.psf';

                    $res_atm = 1;
                    $fit_check = 1;
                }

                #~ $heavy = 0;
                #~ $allid = 0;
            }
            else {

                #~ my $line_count = 1;
                #~ my $regex_var = '';
#~
                #~ $regex_var = qr{^(\s*\d+)(\s*)(Z)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)};
#~
                #~ open PSF, '<', "selected_residues.psf" || die "Cannot open selected_residues.psf for reading: $!";
                #~ open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";
#~
                #~ while ( <PSF> ) {
#~
                    #~ if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {
#~
                        #~ last;
                    #~ }
                    #~ elsif ( /$regex_var/i ) {
#~
                        #~ print OUT "$1$2$3$4$5$6\n";
                    #~ }
                #~ }
#~
                #~ close OUT;
                #~ close PSF;

                $active_dcd = "carma.$input.cluster_0$i.dcd";
                $active_psf = "selected_residues.psf";

                if ( $input eq 'dPCA' and $chi1 ) {

                    $flag = " -v -w -fit $res_id_flag -atmid ALLID";
                }
                else {

                    $flag = " -v -w -fit $res_id_flag -atmid C -atmid CA -atmid N -atmid O";
                }

                &carma ( 'auto' );

                if ( $all_done ) {

                    #~ if ( $linux or $mac ) {
#~
                        #~ `carma -v -w -last 1 -atmid CA -atmid C -atmid N -atmid O -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                    #~ }
                    #~ else {
#~
                        #~ `carma.exe -v -w -last 1 -atmid CA -atmid C -atmid N -atmid O -segid Z carma.cluster_0$i.dcd selected_residues.psf`;
                    #~ }
#~
                    #~ open IN, '<', "carma.selected_atoms.psf" or die "Cannot open carma.selected_atoms.psf for reading: $!\n";
                    #~ open OUT, '>', "new.selected_residues.psf" or die "Cannot open new.selected_residues.psf for writing: $!\n";
#~
                    #~ while ( <IN> ) {
#~
                        #~ print OUT $_;
                    #~ }
#~
                    #~ close ( OUT );
                    #~ close ( IN );
#~
                    #~ $active_psf = 'new.selected_residues.psf';

                    $res = 1;
                    $fit_check = 1;
                }
            }
        }
        elsif ( $custom_id_flag ) {

            my @selected_atoms = split ' -atmid ', $custom_id_flag;
            shift @selected_atoms;

            my $line_count = 1;
            my $regex_var = '';

            {
                local $" = '|';
                $regex_var = qr{^(\s*\d+)(\s*)(\w+)(\s*\d+\s*\w+\s+)(@selected_atoms)(\s+.*)};
            }

            open PSF, '<', $psf_file || die "Cannot open $active_psf for reading: $!";
            open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";

            while ( <PSF> ) {

                if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                    last;
                }
                elsif ( /$regex_var/i ) {

                    print OUT "$1$2$3$4$5$6\n";
                }
            }

            close PSF;
            close OUT;

            $active_dcd = "carma.$input.cluster_0$i.dcd";

            $flag = " -v -w -fit -atmid ALLID -index";
            &carma ( 'auto' );

            if ( $all_done ) {

                $custom = 1;
                $fit_check = 1;
            }
        }
        elsif ( $atm_id_flag ) {

            my $heavy = 0;
            $heavy = 1 if ( $atm_id_flag =~ /HEAVY/i );
            my $allid = 0;
            $allid = 1 if ( $atm_id_flag =~ /ALLID/i );

            my $line_count = 1;
            my $regex_var = '';

            $regex_var = qr{^(\s*\d+)(\s*)(\w+)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)} if ( $atm_id =~ /BACKBONE/i );
            $regex_var = qr{^(\s*\d+)(\s*\w+)(\s*\d+)(\s*\w+\s+)(\w+)(.*)} if ( $atm_id_flag =~ /(HEAVY|ALLID)/ );

            open PSF, '<', $psf_file || die "Cannot open $active_psf for reading: $!";
            open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

            while ( <PSF> ) {

                if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                    last;
                }
                elsif ( /$regex_var/i ) {

                    my $line = $1 . $2 . $3 . $4 . $5 . $6;

                    if ( $heavy && $5 !~ /^H/ ) {

                        print OUT "$line\n";
                    }
                    elsif ( $allid || $atm_id =~ /BACKBONE/i ) {

                        print OUT "$line\n";
                    }
                }
            }

            close OUT;
            close PSF;

            $active_dcd = "carma.$input.cluster_0$i.dcd";

            $flag = " -v -w -fit -index -atmid ALLID";
            &carma ( 'auto' );

            if ( $all_done ) {

                $atm = 1;
                $fit_check = 1;
            }

            $heavy = 0;
            $allid = 0;
        }
        else {

            my $line_count = 1;
            my $regex_var = '';

            $regex_var = qr{^(\s*\d+)(\s*)(\w+)(\s*\d+\s*\w+\s+)($backbone)(\s+.*)};

            open PSF, '<', $active_psf || die "Cannot open $active_psf for reading: $!";
            open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!";

            while ( <PSF> ) {

                if ( /!N(BOND|THETA|PHI|IMPHI|DON|ACC|NBB|GRP)/ ) {

                    last;
                }
                elsif ( /$regex_var/i ) {

                    print OUT "$1$2$3$4$5$6\n";
                }
            }

            close OUT;
            close PSF;

            $active_dcd = "carma.$input.cluster_0$i.dcd";

            $flag = " -v -w -fit -index -atmid ALLID";
            &carma ( 'auto' );

            if ( $all_done ) {

                $nothing = 1;
                $fit_check = 1;
            }
        }

        mv ( "carma.fit-rms.dat", "$input.rms_from_first_frame.cluster_0$i.dat" );

        if ( $fit_check ) {

            mv ( "carma.fitted.dcd", "carma.$input.fitted.cluster_0$i.dcd" );
            $active_dcd = "carma.$input.fitted.cluster_0$i.dcd";

            if ( $seg_res ) {

                if ( $input eq 'dPCA' ) {

					if ( $chi1 ) {

						$flag = " -v -w -col -cov -dot -norm -super $seg_id_flag $res_id_flag -atmid ALLID";
					}
					else {

						$flag = " -v -w -col -cov -dot -norm -super $seg_id_flag $res_id_flag -atmid C -atmid CA -atmid N -atmid O";
					}
                }
                else {

                    if ( $atm_id_flag ) {

                        $flag = " -v -w -col -cov -dot -norm -super $seg_id_flag $res_id_flag $atm_id_flag";
                    }
                    else {

                        $flag = " -v -w -col -cov -dot -norm -super $seg_id_flag $res_id_flag -atmid C -atmid CA -atmid N -atmid O";
                    }
                }

                &carma ( 'auto' );

                $seg_res = 0;
            }
            elsif ( $seg_custom || $seg_atm ) {

                $flag = " -v -w -col -cov -dot -norm -super $seg_id_flag $custom_id_flag $atm_id_flag";
                &carma ( 'auto' );

                $seg_custom = 0;
                $seg_atm = 0;
            }
            elsif ( $seg ) {

                $flag = " -v -w -col -cov -dot -norm -super $seg_id_flag -atmid CA -atmid C -atmid N -atmid O";
                &carma ( 'auto' );

                $seg = 0;
            }
            elsif ( $res_custom || $res_atm || $res ) {

                if ( $linux or $mac ) {

                    if ( $input eq 'dPCA' ) {

                        if ( $chi1 ) {

                            `carma -v -w -last 1 -atmid ALLID -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        else {

                            `carma -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                    }
                    else {

                        if ( $custom_id_flag ) {

                            `carma -v -w -last 1 $custom_id_flag -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        elsif ( $atm_id_flag ) {

                            `carma -v -w -last 1 $atm_id_flag -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        else {

                            `carma -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                    }
                }
                else {

                    if ( $input eq 'dPCA' ) {

                        if ( $chi1 ) {

                            `carma.exe -v -w -last 1 -atmid ALLID -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        else {

                            `carma.exe -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                    }
                    else {

                        if ( $custom_id_flag ) {

                            `carma.exe -v -w -last 1 $custom_id_flag -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        elsif ( $atm_id_flag ) {

                            `carma.exe -v -w -last 1 $atm_id_flag -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                        else {

                            `carma.exe -v -w -last 1 -atmid C -atmid CA -atmid N -atmid O -segid Z carma.$input.cluster_0$i.dcd selected_residues.psf`;
                        }
                    }
                }

                open IN, '<', "carma.selected_atoms.psf" or die "Cannot open carma.selected_atoms.psf for reading: $!\n";
                open OUT, '>', "new.selected_residues.psf" or die "Cannot open new.selected_residues.psf for writing: $!\n";

                while ( <IN> ) {

                    print OUT $_;
                }

                close ( OUT );
                close ( IN );

                $active_psf = 'new.selected_residues.psf';
                $active_dcd = "carma.$input.fitted.cluster_0$i.dcd";

                if ( $input eq 'cPCA' ) {

                    $flag = " -v -w -col -cov -dot -norm -super -segid Z $custom_id_flag $atm_id_flag";
                }
                else {

                    if ( $chi1 ) {

                        $flag = " -v -w -col -cov -dot -norm -super -segid Z -atmid ALLID";
                    }
                    else {

                        $flag = " -v -w -col -cov -dot -norm -super -segid Z";
                    }
                }

                &carma ( 'auto' );

                $res_custom = 0;
                $res_atm = 0;
                $res = 0;
            }
            #~ elsif ( $res ) {
#~
                #~ $active_dcd = "carma.fitted.cluster_0$i.dcd";
#~
                #~ $flag = " -v -w -col -cov -dot -norm -super";
                #~ &carma ( 'auto' );
#~
                #~ $res = 0;
            #~ }
            elsif ( $custom || $atm ) {

                $active_dcd = "carma.$input.fitted.cluster_0$i.dcd";

                $flag = " -v -w -col -cov -dot -norm -super $custom_id_flag $atm_id_flag";
                &carma ( 'auto' );

                $custom = 0;
                $atm = 0;
            }
            elsif ( $nothing ) {

                $active_dcd = "carma.$input.fitted.cluster_0$i.dcd";

                $flag = " -v -w -col -cov -dot -norm -super -atmid C -atmid CA -atmid N -atmid O";
                &carma ( 'auto' );

                $nothing = 0;
            }

            if ( $all_done ) {

                mv ( "carma.superposition.pdb", "$input.superposition.cluster_0$i.pdb" );
                mv ( "carma.average.pdb", "$input.average.cluster_0$i.pdb" );

				opendir CWD, getcwd || die "Cannot open " . getcwd . ": $!";
				while ( my $dh = readdir CWD ) {

					if ( $dh =~ /carma.\w+.fitted.cluster_(\d+).dcd.varcov.ps/ ) {

						mv ( "$dh", "$input.covariance.cluster_$1.ps" );
					}
				}
				closedir CWD;

                $fit_check = 0;
                $super_check = 1;
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
            }

            open IN, '<', "carma.rms-average.dat" || die "Cannot open carma.rms-average.dat for reading: $!";

            my $smallest = 1000;
            my $frame;
            while ( <IN> ) {

                if ( /^\s+(\d+)\s+(\d+\.\d+).*?$/ ) {

                    if ( $2 < $smallest ) {

                        $smallest = $2;
                        $frame = $1;
                    }
                }
            }

            close IN;
            mv ( "carma.rms-average.dat", "$input.rms_from_average_structure.cluster_0$i.dat" );

                if ( $linux or $mac ) {

                    if ( $input eq 'dPCA' ) {

                        if ( $chi1 ) {

                            `carma -v -w -atmid ALLID $seg_id_flag $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma -v -w -atmid C -atmid CA -atmid N -atmid O $seg_id_flag $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }
                    else {

                        if ( $include_segid or $atm_id_flag ) {

                            `carma -v -w $atm_id_flag $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        elsif ( $custom_id_flag ) {

                            `carma -v -w $custom_id_flag $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma -v -w -atmid C -atmid CA -atmid N -atmid O $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }
                }
                else {

                    if ( $input eq 'dPCA' ) {

                        if ( $chi1 ) {

                            `carma.exe -v -w -atmid ALLID $seg_id_flag $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma.exe -v -w -atmid C -atmid CA -atmid N -atmid O $seg_id_flag $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }
                    else {

                        if ( $include_segid or $atm_id_flag ) {

                            `carma.exe -v -w $atm_id_flag $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        elsif ( $custom_id_flag ) {

                            `carma.exe -v -w $custom_id_flag $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma.exe -v -w -atmid C -atmid CA -atmid N -atmid O $res_id_flag $seg_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }
                }

            #~ if ( $linux || $mac ) {
#~
                #~ if ( $chi1 ) {
#~
                    #~ if ( $include_segid ) {
#~
                        #~ `carma -v -w -atmid ALLID -first $frame -last $frame -pdb $active_dcd $active_psf`;
                    #~ }
                    #~ else {
#~
                        #~ `carma -v -w -atmid ALLID $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                    #~ }
                #~ }
                #~ else {
#~
                    #~ if ( $include_segid ) {
#~
                        #~ `carma -v -w -atmid C -atmid CA -atmid N -atmid O -first $frame -last $frame -pdb $active_dcd $active_psf`;
                    #~ }
                    #~ else {
#~
                        #~ `carma -v -w -atmid C -atmid CA -atmid N -atmid O $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                    #~ }
                #~ }
            #~ }
            #~ else {
#~
                #~ if ( $chi1 ) {
#~
                    #~ `carma.exe -v -w -atmid ALLID -first $frame -last $frame -pdb $active_dcd $active_psf`;
                #~ }
                #~ else {
#~
                    #~ `carma.exe -v -w -atmid C -atmid CA -atmid N -atmid O -first $frame -last $frame -pdb $active_dcd $active_psf`;
                #~ }
            #~ }

            $frame = sprintf ( "%.7d", $frame, );
            mv ( "carma.$input.fitted.cluster_0$i.dcd.$frame.pdb", "$input.representative.cluster_0$i.pdb" );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
        }
    }
    $active_dcd = $remember_dcd;
    $active_psf = $remember_psf;
}

###################################################################################################
###   Draw the window for covariance, average and representative structure calculation          ###
###################################################################################################

sub cov_avg_rep_window {

    my $avg_dot = '';
    my $avg_norm = '';
    my $avg_mass = '';
    my $avg_first = 1;
    my $avg_last = dcd_header_parser( "avg" );
    my $avg_step = 1;
    my $avg_reverse = '';
    my $avg_first_flag = '';
    my $avg_last_flag = '';
    my $avg_step_flag = '';
    my $top_avg;

    if ( !Exists ( $top_avg ) ) {

        $top_avg = $mw -> Toplevel( -title => 'Average and representative structures', );
        $top_avg -> geometry("$toplevel_position");
        $top_avg -> protocol( 'WM_DELETE_WINDOW' => sub { $top_avg -> withdraw }, );

        my $frame_avg1 = $top_avg -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_avg2 = $top_avg -> Frame() -> pack( -expand => 1, -fill => 'x', );
        my $frame_avg3 = $top_avg -> Frame() -> pack( -expand => 1, -fill => 'x', );

        &radiobuttons ( $frame_avg1 );
        &checkbuttons ( $frame_avg2 );
        &otherbuttons ( $frame_avg3 );

        my $frame_avg4 = $top_avg -> Frame() -> pack( -fill => 'x', );
        $frame_avg4 -> Label( -text => 'Various Options' )
                              -> pack( -side => 'top', );

        my $avg_dot_b = $frame_avg4 -> Checkbutton( -text => 'Use dot product (needed for average structures)',
                                    -variable => \$avg_dot,
                                    -offvalue => '',
                                    -onvalue => " -dot", )
                                    -> pack( -side => 'top', -anchor => 'w', );
        $avg_dot_b -> select;
        $frame_avg4 -> Checkbutton( -text => 'Calculate normalised matrices',
                                    -variable => \$avg_norm,
                                    -offvalue => '',
                                    -onvalue => " -norm", )
                                    -> pack( -side => 'top', -anchor => 'w', );
        $frame_avg4 -> Checkbutton( -text => 'Calculate mass-weighted matrices',
                                    -variable => \$avg_mass,
                                    -offvalue => '',
                                    -onvalue => " -mass", )
                                    -> pack( -side => 'top', -anchor => 'w', );

        my $frame_avg5 = $top_avg -> Frame()-> pack( -expand => 0, );

        $frame_avg5 -> Label( -text => 'First frame to use: ', )
                              -> grid( -row => 1, -column => 1, );
        $frame_avg5 -> Entry( -textvariable => \$avg_first, )
                              -> grid( -row => 1, -column => 2, );
        $frame_avg5 -> Label( -text => 'Last frame to use: ', )
                              -> grid( -row => 2, -column => 1, );
        $frame_avg5 -> Entry( -textvariable => \$avg_last, )
                              -> grid( -row => 2, -column => 2, );
        $frame_avg5 -> Label( -text => 'Stride (step) between frames: ', )
                              -> grid( -row => 3, -column => 1, );
        $frame_avg5 -> Entry( -textvariable => \$avg_step, )
                              -> grid( -row => 3, -column => 2, );

        my $frame_avg6 = $top_avg -> Frame() -> pack( -expand => 0, );

        $frame_avg6 -> Button( -text => 'Return',
                               -command => [ $top_avg => 'withdraw' ], )
                               -> pack( -side => 'left', );

        $frame_avg6 -> Button( -text => 'Run',
                               -command => sub {

            $top_avg -> destroy;

            $avg_first_flag = ( ( $avg_first != 1 ) ? " -first $avg_first" : '' );
            $avg_last_flag = ( ( $avg_last != $header ) ? " -last $avg_last" : '' );
            $avg_step_flag = ( ( $avg_step != 1 ) ? " -step $avg_step" : '' );

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            &create_dir;

            $text -> insert( 'end', "\nNow calculating average and representative structures. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            if ( $seg_id_flag ) {

                $flag = " -v -w -col -cov $avg_dot $avg_norm $avg_mass $avg_step_flag $avg_last_flag $avg_first_flag $avg_reverse $atm_id_flag $seg_id_flag $res_id_flag -super";
            }
            else {

                $flag = " -v -w -col -cov $avg_dot $avg_norm $avg_mass $avg_step_flag $avg_last_flag $avg_first_flag $avg_reverse $atm_id_flag $res_id_flag -super";
            }

            &carma;

            if ( $all_done ) {

                if ( $avg_dot ) {

                    open IN, '<', "carma.rms-average.dat" || die "Cannot open carma.rms-average.dat for reading: $!";

                    my $smallest = 1000;
                    my $frame;
                    while ( <IN> ) {

                        if ( /^\s+(\d+)\s+(\d+\.\d+).*?$/ ) {

                            if ( $2 < $smallest ) {

                                $smallest = $2;
                                $frame = $1;
                            }
                        }
                    }

                    close IN;

                    if ( $linux || $mac ) {

                        if ( $res_id_flag ) {

                            `carma -v -w -atmid ALLID $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma -v -w -atmid ALLID -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }
                    else {

                        if ( $res_id_flag ) {

                            `carma.exe -v -w -atmid ALLID $res_id_flag -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                        else {

                            `carma.exe -v -w -atmid ALLID -first $frame -last $frame -pdb $active_dcd $active_psf`;
                        }
                    }

                    $frame = sprintf ( "%.7d", $frame, );
                }

                $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
                $text -> see( 'end', );
                $image_menu -> configure( -state => 'normal', );
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
        }, )
        -> pack( -side => 'right', );
    }
    else {

        $top_avg -> deiconify;
        $top_avg -> raise;
    }
}

###################################################################################################
###   Calculate secondary structure with stride                                                 ###
###################################################################################################

sub stride_window {

    my $top_stride;
    my $stride_first = 1;
    my $stride_first_flag;
    my $stride_last = dcd_header_parser ( 'rmsd' );
    my $stride_last_flag;
    my $stride_step;
    my $stride_step_flag;

    if ( !Exists ( $top_stride ) ) {

        if ( $stride_last <= 30000 ) {

            $stride_step = 1;
        }
        elsif ( $stride_last > 30000 ) {

            $stride_step = int ( ( $stride_last / 30000 ) + 0.5 );
        }

        $top_stride = $mw -> Toplevel( -title => 'Secondary structure calculation', );
        $top_stride -> geometry("$toplevel_position");
        $top_stride -> protocol( 'WM_DELETE_WINDOW' => sub { $top_stride -> withdraw }, );

        my $frame_stride2 = $top_stride -> Frame() -> pack( -fill => 'x', );
        my $frame_stride3 = $top_stride -> Frame() -> pack( -fill => 'x', );
        our $frame_stride1 = $top_stride -> Frame() -> pack( -fill => 'x', );

        $frame_stride1 -> Label( -text => "\n", )
                                 -> grid( -row => 0, -column => 0, );
        $frame_stride1 -> Label( -text => 'First frame to use: ', )
                                 -> grid( -row => 1, -column => 1, );
        $frame_stride1 -> Entry( -textvariable => \$stride_first, )
                                 -> grid( -row => 1, -column => 2, );
        $frame_stride1 -> Label( -text => 'Last frame to use: ', )
                                 -> grid( -row => 2, -column => 1, );
        $frame_stride1 -> Entry( -textvariable => \$stride_last, )
                                 -> grid( -row => 2, -column => 2, );
        $frame_stride1 -> Label( -text => 'Stride (step) between frames: ', )
                                 -> grid( -row => 3, -column => 1, );
        $frame_stride1 -> Entry( -textvariable => \$stride_step, )
                                 -> grid( -row => 3, -column => 2, );

        &checkbuttons ( $frame_stride2 );
        &otherbuttons ( $frame_stride3 );

        my $frame_stride4 = $top_stride -> Frame() -> pack( -expand => 0, );

        $frame_stride4 -> Button( -text => 'Return',
                               -command => [ $top_stride => 'withdraw' ], )
                               -> pack( -side => 'left', );

        $frame_stride4 -> Button( -text => 'Run',
                               -command => sub {

        $stride_first_flag = ( ( $stride_first != 1 ) ? " -first $stride_first" : '' );
        $stride_last_flag = ( ( $stride_last != $header ) ? " -last $stride_last" : '' );
        $stride_step_flag = ( ( $stride_step != 1 ) ? " -step $stride_step" : '' );

        $top_stride -> destroy;

        $seg_id_flag = '' if $seg_id_flag;

        foreach ( @seg_ids ) {

            if ( defined ( $_ ) ) {

                $seg_id_flag = $seg_id_flag . $_;
            }
        }

        if ( $seg_id_flag ) {

            $flag = " -w -v -pdb -stride -atmid HEAVY $stride_first_flag $stride_last_flag $stride_step_flag $res_id_flag $seg_id_flag $custom_id_flag";
        }
        else {

            $flag = " -w -v -pdb -stride -atmid HEAVY $stride_first_flag $stride_last_flag $stride_step_flag $res_id_flag $custom_id_flag";
        }

        create_dir( 'stride' );

        $text -> insert( 'end', "\nNow calculating secondary structure. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );

            opendir TMPDIR, "." or die "Cannot open . for reading : $!\n";
            while ( my $dh = readdir TMPDIR ) {

                mv ( "$dh", ".." ) unless ( $dh =~ /\.\./ );
            }

            closedir TMPDIR;
            chdir ( ".." );
            rmdir ( "tmp" );

            if ( $weblogo or $seqlogo ) {

				$text -> insert( 'end', "Now running weblogo/seqlogo on carma.stride.dat . . . ", 'valid' );
				$text -> see( 'end', );

                open PSF, '<', 'carma.selected_atoms.psf' or die "Cannot open carma.selected_atoms.psf for reading : $!\n";

                my $residues = 0;
                my %residues;
                my $columns = 0;
                my @columns;

                if ( ( $res_id_flag and not $seg_id_flag ) or ( $res_id_flag and $seg_id_flag ) ) {

                    while ( <PSF> ) {

                        if ( /\d+\s+Z\s+(\d+)\s+\w+\s+\w+/ ) {

                            $residues = $1;
                        }
                    }
                }
                else {

                     while ( <PSF> ) {

                       if ( /\d+\s+([A-Z])\s+(\d+)\s+\w+\s+\w+/ ) {

                            $residues{$1} = $2;
                        }
                    }
                }

                close PSF;

                if ( $residues or scalar ( keys %residues ) == 1 ) {

                    if ( $residues ) {

                        $columns = $residues;
                    }
                    else {

                         foreach ( keys %residues ) {

                            $columns = $residues{$_};
                        }
                    }

                    open STRIDE, '<', "carma.stride.dat" or die "Cannot open carma.stride.dat for reading : $!\n";
                    open OUT, '>', "temp.dat" or die "Cannot open temp.dat for writing : $!\n";
                    open OUT1, '>', "stride_plot.dat" or die "Cannot open temp.dat for writing : $!\n";

                    #~ my $line;
                    my $new_line;
                    while ( <STRIDE> ) {

                        $new_line = substr( $_, 0, $columns, '', );
                        $new_line =~ s/ /C/g;
                        $new_line =~ s/b/B/g;
                        print OUT ">\n$new_line\n";
                        print OUT1 "$new_line\n";
                    }

                    close STRIDE;
                    close OUT;
                    close OUT1;

                    if ( $weblogo ) {

                        `weblogo -C '#600080' I 'pi helix' -C '#6080FF' B 'b turn' -C '#6080FF' T 'b turn' -C '#A00080' G '3-10 helix' -C '#FF0080' H 'a-helix' -C 'green' C 'coil' -C '#FFC800' E 'sheet' --composition none -a 'GTCHEBI' < temp.dat > sec_structure.eps`;
                    }
                    elsif ( $seqlogo ) {

                        `seqlogo -Y -C 40 -w 20 -f temp.dat > sec_structure.eps`;
                    }

                    unlink ( "temp.dat" );

                }
                elsif ( scalar ( keys %residues ) > 1 ) {

                    my $i = 0;
                    my $offset = 0;
                    foreach ( keys %residues ) {

                        open STRIDE, '<', "carma.stride.dat" or die "Cannot open carma.stride.dat for reading : $!\n";
                        open OUT, '>', "stride_chain$_.dat" or die "Cannot open stride_chain$_.dat for reading : $!\n";
                        open OUT1, '>', "stride_plot_chain$_.dat" or die "Cannot open stride_chain$_.dat for reading : $!\n";

                        if ( $i != 0 ) {

                            if ( $columns <= 50 ) {

                                $offset = 50;
                            }
                            elsif ( $columns > 50 and $columns <= 100 ) {

                                $offset = 100;
                            }
                            elsif ( $columns > 100 and $columns <= 150 ) {

                                $offset = 150;
                            }
                            elsif ( $columns > 150 and $columns <= 200 ) {

                                $offset = 200;
                            }

                            $columns = $residues{$_};
                        }
                        else {

                            $columns = $residues{$_};
                        }

                        my $line;
                        my $new_line;
                        while ( $line = <STRIDE> ) {

                            $new_line = substr( $line, $offset, $columns, '', );
                            $new_line =~ s/ /C/g;
                            $new_line =~ s/b/B/g;
                            print OUT ">\n$new_line\n";
                            print OUT1 "$new_line\n";
                        }
                        close OUT;
                        close OUT1;
                        close STRIDE;

                        if ( $weblogo ) {

                            `weblogo -C '#600080' I 'pi helix' -C '#6080FF' B 'b turn' -C '#6080FF' T 'b turn' -C '#A00080' G '3-10 helix' -C '#FF0080' H 'a-helix' -C 'green' C 'coil' -C '#FFC800' E 'sheet' --composition none -a 'GTCHEBI' < stride_chain$_.dat > sec_structure_chain$_.eps`;
                        }
                        elsif ( $seqlogo ) {

                            `seqlogo -Y -C 40 -w 20 -f stride_chain$_.dat > sec_structure_chain$_.eps`;
                        }

                        #~ unlink ( "stride_chain$_.dat" );

                        $i++;
                    }
                }

				$text -> insert( 'end', "Done.\n", 'valid' );
				$text -> see( 'end', );
			}
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
            $text -> see( 'end', );
        }
        }, )-> pack( -side => 'right', );
    }
    else {

        $top_stride -> deiconify;
        $top_stride -> raise;
    }
}

###################################################################################################
###   Draw the window for viewing the .ps images                                                ###
###################################################################################################

sub image_window {

    my $i = 0;
    my $j = 0;
    my ( @pdb, @dat, @ps, );

    my $files =
        'carma.Qfraction.dat|' .
        'carma.Rgyration.dat|' .
        'carma.surface.dat|' .
        'carma.distances|' .
        'carma.fit-rms.dat|' .
        'carma.rms-average.dat|' .
        '.PCA.rms_from_*.*.dat|' .
        'carma.torsions|' .
        'phi_psi_dihedral_segid.*.dat|' .
        'carma.bendangles|' .
        '.PCA.rms_from_*.*.dat|' .
        'carma_entropy.dat|' .
        'carma.variance_explained.dat|' .
        'stride_plot*|' .
        'carma.stride.dat';

    if ( $vmd ) {

        $files .= '|.*.cns';
    }

    our $image_top = $mw -> Toplevel( -title => 'Latest Results', );
    $image_top -> geometry("$toplevel_position");

    opendir IMAGE_DIR, getcwd || die "Cannot open " . getcwd . ": $!";
    while ( my $dh = readdir IMAGE_DIR ) {

        if ( $dh =~ /.*.ps$/ ) {

            push @ps, $dh;
        }
        elsif ( $dh =~ /$files/ ) {

            push @dat, $dh;
        }
        elsif ( $dh =~ /.*\.pdb$/ ) {

            push @pdb, $dh;
        }
    }
    closedir IMAGE_DIR;

    @pdb = sort ( @pdb );
    @dat = sort ( @dat );
    @ps = sort ( @ps );

    my $dir = getcwd;

    my $frame_image1 = $image_top -> Frame() -> grid( -row => 5, -column => 1, );
    my $frame_image2 = $image_top -> Frame() -> grid( -row => 5, -column => 3, );
    my $frame_image3 = $image_top -> Frame() -> grid( -row => 5, -column => 2, );
    my $frame_image4 = $image_top -> Frame() -> grid( -row => 6, -column => 1, );
    my $frame_image5 = $image_top -> Frame() -> grid( -row => 6, -column => 3, );
    my $frame_image6 = $image_top -> Frame() -> grid( -row => 7, -column => 2, );

    $image_top -> Label( -text => "Displaying contens of the folder", ) -> grid( -row => 1, -column => 2, );
    $image_top -> Entry( -text => $dir, -width => 0, ) -> grid( -row => 2, -column => 2, );
    $image_top -> Label( -text => "\nClick on the image you want to view", ) -> grid( -row => 3, -column => 2, );
    $image_top -> Label( -text => "or the file you would like to plot\n", ) -> grid( -row => 4, -column => 2, );

    $frame_image1 -> Label( -text => 'Available pdb files', ) -> pack;
    $frame_image2 -> Label( -text => 'Available numerical files', ) -> pack;
    $frame_image3 -> Label( -text => 'Available postscript files', ) -> pack;

    my $lb1 = $frame_image1 -> Scrolled( "Listbox", -scrollbars => 'oe', -selectmode => "single", -width => 28, ) -> pack;
    my $lb2 = $frame_image2 -> Scrolled( "Listbox", -scrollbars => 'oe', -selectmode => "single", -width => 40, ) -> pack;
    my $lb3 = $frame_image3 -> Scrolled( "Listbox", -scrollbars => 'oe', -selectmode => "single", -width => 30, ) -> pack;

    my $vmd_check;
    my $vmd_check_var;
    if ( $vmd ) {

        $vmd_check = $frame_image4 -> Checkbutton( -text => 'Use VMD to view .pdb files',
                                                   -variable => \$vmd_check_var, )
                                                   -> pack( -side => 'left', );
    }

    $frame_image5 -> Button( -text => 'Empty the current working directory',
                             -command => sub {

        my $response = $frame_image5 -> messageBox( -message => "Are you sure? All non psf/dcd files will be permanently deleted.",
                                                    -type => 'yesno',
                                                    -icon => 'question', );

        if ( $response =~ /yes/i ) {

            $image_top -> destroy;
            $image_menu -> configure( -state => 'disabled', );

            opendir CWD, getcwd or die "Cannot open cwd: $!";
            while ( my $cwd = readdir CWD ) {

                unless ( $cwd =~ /psf$|dcd$/ ) {

                    unlink $cwd;
                }
            }

            closedir CWD;
        }
    }, ) -> pack( -side => 'right', );

    $frame_image6 -> Button( -text => 'Return',
                             -command => [ $image_top => 'destroy' ], )
                             -> pack;

    $lb1 -> insert( 'end', @pdb, );
    $lb2 -> insert( 'end', @dat, );
    $lb3 -> insert( 'end', @ps, );

    $lb1 -> bind( '<Button-1>', sub {

        my $selection = $lb1 -> get( $lb1 -> curselection() );

        if ( $vmd_check_var ) {

            system ( "vmd $selection" ) if ( $linux || $mac );
        }
        else {

            system ( "$pdb_viewer $selection &" ) if ( ( $linux || $mac ) && $pdb_viewer );
            `start $selection` if ( $windows );
        }
    } );
    $lb2 -> bind( '<Button-1>', sub {

        my $selection = $lb2 -> get( $lb2 -> curselection() );

        if ( $selection =~ /cns$/ ) {

            system ( "vmd $selection" );
        }
        elsif ( $selection =~ /carma.stride/ ) {

            my $temp_w = MainWindow -> new( -title => 'carma.stride.dat', );
            my $temp_t = $temp_w -> Scrolled( 'ROText', -wrap => 'none', ) -> pack;

            open STRIDE, '<', "carma.stride.dat" or die "Cannor open carma.stride.dat for reading : $!\n";

            while ( <STRIDE> ) {

                $temp_t -> insert( 'end', "$_" );
            }
            close STRIDE;
        }
        elsif ( $selection =~ /stride_plot/ ) {

            {
                local $/ = \1;

                my $temp_w = MainWindow -> new( -title => 'Secondary structure plot', );
                $temp_w -> configure( -menu => my $menubar = $temp_w -> Menu );

				my $file = $menubar -> cascade( -label => '~File' );

                my $nofres = length ( `head -1 $selection` ) - 1;
                my $frames;

                if ( `wc $selection` =~ /(\d+)/ ) {

                    $frames = $1;
                }

                my $height = $temp_w -> screenheight - 100;
                my $width = $temp_w -> screenwidth;
                my $color = '';

                my $y_step = $height / $nofres;
                my $x_step = $width / $frames;

                our $canvas = $temp_w -> Canvas( -cursor=>"crosshair",
                                                 -height => $height,
                                                 -width => $width, ) -> pack( -fill => 'both',
																			  -expand => 1, );

				$temp_w -> update;
				my $currentSize = $temp_w -> reqwidth . "x" . $temp_w -> reqheight;
				my $newsize;

				$temp_w -> bind( '<Configure>' => [ \&OnResize, \$currentSize, \$selection, \$nofres, \$frames, ] );
				$temp_w -> update;

				$file -> command(
					-label       => 'Save As Postscript',
					-accelerator => 'Ctrl-s',
					-underline   => 0,
					-command     => sub {

						$canvas -> update;
						$canvas -> postscript( -file => "ss_plot.eps", -colormode => 'color', );
					}
				);
				$file->separator;
				$file->command(
					-label       => "Close",
					-accelerator => 'Ctrl-q',
					-underline   => 0,
					-command     => sub { $mw -> destroy; },
				);

				$temp_w -> bind( $temp_w, "<Control-s>" => sub {

						$canvas -> update;
						$canvas -> postscript( -file => "ss_plot.eps", -colormode => 'color', );
					}
				);

				$temp_w -> bind( $temp_w, "<Control-q>" => sub { $temp_w -> destroy; }
				);

                open FILE, '<', $selection or die "Cannot open $selection for reading : $!\n";

                my ( $x, $y, ) = ( 0, 0, );
                while ( <FILE> ) {

                    if ( $_ eq 'H' ) {

                        $color = '#FF0080';
                    }
                    elsif ( $_ eq 'G' ) {

                        $color = '#A00080';
                    }
                    elsif ( $_ eq 'I' ) {

                        $color = '#600080';
                    }
                    elsif ( $_ eq 'E' ) {

                        $color = '#FFC800';
                    }
                    elsif ( $_ eq 'B' or $_ eq 'T' ) {

                        $color = '#6080FF';
                    }
                    elsif ( $_ eq 'C' ) {

                        $color = '#FFFFFF';
                    }

                    $canvas -> createRectangle( ( $x * $x_step ), ( $height - ( $y_step * ( $y + 1 ) ) ), ( ( $x + 1 ) * $x_step ), ( $height - ( $y_step * $y ) ), -fill => "$color", -outline => undef, ) unless ( $color eq '#FFFFFF' );

                    $y++;
                    if ( $y == $nofres+1 ) {

                        $y = 0;
                        $x++;
                    }
                }

                close FILE;
            }
        }
        elsif ( $selection =~ /phi_psi/ ) {

            our ( $first_residue, $last_residue, $number_of_residues, $correction, $temp_segid );

            my $response = $mw -> messageBox(

                -message => "The file carma.torsions contains the phi/psi angles" .
                            " for residues $first_residue to $last_residue of chain $temp_segid " .
                            ". Would you like to view these results in a Ramachandran" .
                            " plot ?",
                -icon => 'question',
                -type => 'yesno', );

            if ( $response =~ /yes/i ) {

                my $entry_var = "$first_residue-$last_residue;";
                my $top = $mw -> Toplevel( -title => 'phi/psi dihedral angles' );
                $top -> Label( -text => "$number_of_residues pairs of phi/psi angles detected. In case you would\n" .
                                        "like to plot only a subset or subsets of those residues,\n" .
                                        "please define them using the textbox below", ) -> pack;

                $top -> Entry( -textvariable => \$entry_var, ) -> pack;

                my $semicolon_count = 0;
                my @range_low;
                my @range_high;
                $top -> Button( -text => 'Plot',
                                -command => sub {

                    $top -> destroy;

                    if ( $entry_var =~ /;/ ) {

                        $semicolon_count = $entry_var =~ tr/;//;
                    }

                    $entry_var =~ s/;/\n/g;

                    open FH, '<', \$entry_var or die "Cannot open $entry_var for reading : $!\n";

                    my $j = 0;
                    while ( <FH> ) {

                        if ( /(\d+).?(\d*)/ ) {

                            $range_low[$j] = $1;
                            $range_high[$j] = $2 if $2;
                        }

                        $j++;
                    }

                    close FH;

                    open TORSIONS, '<', "phi_psi_dihedral_segid$temp_segid.dat" or die "Cannot open phi_psi_dihedral_segid$temp_segid.dat for reading : $!\n";
                    #~ open DEBUG, '>', 'debug.dat' or die "Cannot open carma.torsions for reading : $!\n";

                    my ( @phi_angles, @psi_angles, );

                    for ( my $k = 0 ; $k < scalar ( @range_low ) ; $k++ ) {

                        if ( $range_high[$k] ) {

                            for ( my $index = $range_low[$k] ; $index <= $range_high[$k] ; $index++ ) {#print DEBUG $index;

                                my $other_index = 0;

                                while ( <TORSIONS> ) {

                                    $phi_angles[$other_index] = substr $_, 10 + ( ( $index - ( 2 + $correction ) ) * 20 ), 9;
                                    $psi_angles[$other_index] = substr $_, 20 + ( ( $index - ( 2 + $correction ) ) * 20 ), 9;
                                    $other_index++;
                                }

                                seek TORSIONS, 0, 0;
                                $index = sprintf ( "%03d", $index );

                                open OUT, '>>', "phi_psi_temp_angles" or die $!;

                                while ( my $phi_line = shift @phi_angles, my $psi_line = shift @psi_angles, ) {

                                    chomp ( $phi_line, $psi_line, );

                                    print OUT "$phi_line $psi_line\n";
                                }

                                close OUT;
                            }
                        }
                        else {

                            my $index = $range_low[$k];
                            my $other_index = 0;

                            while ( <TORSIONS> ) {

                                $phi_angles[$other_index] = substr $_, 10 + ( ( $index - ( 2 + $correction ) ) * 20 ), 9;
                                $psi_angles[$other_index] = substr $_, 20 + ( ( $index - ( 2 + $correction ) ) * 20 ), 9;
                                $other_index++;
                            }

                            seek TORSIONS, 0, 0;
                            $index = sprintf ( "%03d", $index );

                            open OUT, '>>', "phi_psi_temp_angles" or die $!;

                            while ( my $phi_line = shift @phi_angles, my $psi_line = shift @psi_angles, ) {

                                chomp ( $phi_line, $psi_line, );

                                print OUT "$phi_line $psi_line\n";
                            }

                            close OUT;
                        }
                    }

                    close TORSIONS;

                    scatter_plot ( 'ramachandran' );
                }, ) -> pack;
            }
        }
        else {

            plot ( $selection );
        }
    } );
    $lb3 -> bind( '<Button-1>', sub {

        my $selection = $lb3 -> get( $lb3 -> curselection() );

        system ( "$ps_viewer $selection &" ) if ( ( $linux || $mac ) && $ps_viewer );
        `start $selection` if ( $windows );
    } );
}

###################################################################################################
###   Draw the window for residue selection                                                     ###
###################################################################################################

sub select_residues {

    my $pos = '';
    my $prev_line = '';

    &create_dir;
    open PSF_FILE, '<', $psf_file || die "Cannot open $psf_file for reading\n";
    open OUT, '>', "selected_residues.psf" || die "Cannot open selected_residues.psf for writing\n";

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
            if ( /^(\s*\d+\s+)($dropdown_value[$i])(\s+)(\d+)(.+)$/ ) {

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

    $active_psf = 'selected_residues.psf';

    $res_id_flag = " -segid Z";
    $active_run_buttons = 1;

    $count++;

    $dpca_run_button -> configure( -state => 'normal', ) if ( $dpca_run_button );
    $qfract_run_button -> configure( -state => 'normal', ) if ( $qfract_run_button );
    $phi_psi_run_button -> configure( -state => 'normal', ) if ( $phi_psi_run_button );

    $text -> insert ( 'end', "\nYou have submitted a residue selection which " .
                             "resulted in the creation of a new .psf file." .
                             "While the \"Change\" radiobutton is selected all" .
                             " the calculations will be made with the custom " .
                             ".psf file. By selecting the \"All\" radiobutton" .
                             " the selected .psf file reverts to the one " .
                             "originally specified\n", 'info' );
    $text -> see( 'end', );

    $active_psf_label -> configure( -text => "Active .psf: $active_psf", );
}

###################################################################################################
###   Create fit.index                                                                          ###
###################################################################################################

sub create_fit_index {

    my ( $atmid, $selection, $segids, ) = @_;

    my $fit_regex = '';
    my @atom_selection;
    my @segids;
    
    if ( $segids  ) {

        @segids = split '', $segids;
    }

    if ( @segids ) {

        local $" = '|';

        if ( $atm_id_flag ) {

            if ( $atmid =~ /backbone/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)(C|CA|N|O)(\s+.*)$};
            }
            elsif ( $atmid =~ /heavy/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)([^H].*)(\s+.*)$};
            }
            elsif ( $atmid =~ /allid/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)(\w+)(\s+.*)$};
            }
            else {

				$fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)(CA)(\s+.*)$};
			}
        }
        elsif ( $custom_id_flag ) {

            @atom_selection = split ' -atmid', $custom_id_flag;
            shift @atom_selection;

            $fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)(@atom_selection)(\s+.*)$};
        }
        else {

            $fit_regex = qr{^(\s+\d+\s+)(@segids)(\s+)(\d+)(\s+\w+\s+)(CA)(\s+.*)$};
        }
    }
    else {

        if ( $atm_id_flag ) {

            if ( $atmid =~ /backbone/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)(C|CA|N|O)(\s+.*)$};
            }
            elsif ( $atmid =~ /heavy/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)([^H].*)(\s+.*)$};
            }
            elsif ( $atmid =~ /allid/i ) {

                $fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)(\w+)(\s+.*)$};
            }
            else {

				$fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)(CA)(\s+.*)$};
			}
        }
        elsif ( $custom_id_flag ) {

            @atom_selection = split ' -atmid', $custom_id_flag;
            shift @atom_selection;

            $fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)(@atom_selection)(\s+.*)$};
        }
        else {

            $fit_regex = qr{^(\s+\d+\s+)(\w+)(\s+)(\d+)(\s+\w+\s+)(CA)(\s+.*)$};
        }
	}

    # The same as above but for the index  #
    # subroutine                           #

    open PSF, '<', "carma.selected_atoms.psf" || die "Cannot open carma.selected_atoms.psf for reading:$!\n";
    open OUT, '>', "fit.index" || die "Cannot open fit.index for writing: $!\n";

    $index_num_atoms = 0;
    while ( <PSF> ) {

        if ( /(\d*) \!NATOM/ ) {

            $index_num_atoms = $1;
            last;
        }
    }

	if ( $selection =~ /radio/ ) {

		while ( <PSF> ) {

			if ( /$fit_regex/ ) {

				print OUT $_;
			}
		}
	}
	else {

		#~ my $fit_atom_count = 1;
		my $index_pos = '';
		my $line_count = 1;
		for ( my $i = 0 ; $i < $index_bar_count ; $i++ ) {

			if ( $index_pos ) {

				seek PSF, $index_pos, 0;
			}

			while ( my $index_line = <PSF> ) {

				if ( $index_line =~ /$fit_regex/ ) {

					if ( $4 > $upper_fit_limit[$i] ) {

						$index_pos = tell;
						last;
					}

					if ( $4 >= $lower_fit_limit[$i] && $4 <= $upper_fit_limit[$i] ) {

						print OUT "$index_line";
					}
				}
				$line_count++;
			}
		}
	}

    close OUT;
    close PSF_FILE;

    $text -> insert ( 'end', "\nYou have submitted a residue selection which " .
                             "resulted in the creation of a fit.index file.", 'info' );
    $text -> see( 'end', );

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

            my $i;
            my $check = 0;
            for ( $i = 0 ; $i <= $resid_bar_count ; $i++ ) {

                if ( $lower_res_limit[$i] and $upper_res_limit[$i] and $dropdown_value[$i] ) {

                    $check++;
                }
            }

            if ( $check == $i ) {

                if ( $seg_id_flag ) {

                    $seg_id_flag = '';
                }
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
            }
            else {

                $top_res -> messageBox( -message => 'All of the boxes must be filled in order to submit a residue selection',
                                        -icon => 'warning', );
            }
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
    if ( $resid_bar_count == 0 ) {

        foreach ( keys %num_residues ) {

            $dropdown[0] -> insert( 'end', $_ );
        }
    }
}

###################################################################################################
###   Create a new bar for fit.index creation                                                   ###
###################################################################################################

sub add_index_bar {

    $index_row = 1;
    $index_column = 1;

    $frame_fit_bars[$index_bar_count] -> Label( -text => 'From: ', )
                                            -> grid( -row => "$index_row", -column => "$index_column", );
    $frame_fit_bars[$index_bar_count] -> Entry( -textvariable => \$lower_fit_limit[$index_bar_count], )
                                            -> grid( -row => "$index_row", -column => "$index_column" + 1, );
    $frame_fit_bars[$index_bar_count] -> Label( -text => 'To: ', )
                                            -> grid( -row => "$index_row", -column => "$index_column" + 2, );
    $frame_fit_bars[$index_bar_count] -> Entry( -textvariable => \$upper_fit_limit[$index_bar_count], )
                                            -> grid( -row => "$index_row", -column => "$index_column" + 3, );

    $fit_drop[$index_bar_count] = $frame_fit_bars[$index_bar_count] -> BrowseEntry( -label => "in chain: ",
                                                                                -variable => \$fit_drop_value[$index_bar_count], )
                                                                                -> grid( -row => "$index_row", -column => "$index_column" + 4, );
    if ( $index_bar_count == 0 ) {

        foreach ( keys %num_residues ) {

            $fit_drop[0] -> insert( 'end', $_ );
        }
    }
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
    my $entropy_plot;
    my $frames = dcd_header_parser( "entropy" );

    my @a_entropy;
    my @s_entropy;

    if ( !Exists ( $top_ent ) ) {

        # Divide the number of frames in the   #
        # .dcd header by 10 and round it up    #
        if ( $frames ) {

            $ent_step = int ( ( $frames / 10 ) );
        }

        $top_ent = $mw -> Toplevel( -title => 'Solute entropy calculation', );
        $top_ent -> geometry("$toplevel_position");
        $top_ent -> protocol( 'WM_DELETE_WINDOW' => sub { $top_ent -> withdraw }, );

        my $frame_ent1 = $top_ent -> Frame( -borderwidth => 3,
                                            -relief => 'groove',)
                                            -> pack( -fill => 'x', );

        my $mass_check = $frame_ent1 -> Checkbutton( -text => "Use mass weighting",
                                                     -variable => \$ent_mass,
                                                     -onvalue => '-mass',
                                                     -offvalue => '', )
                                                     -> grid( -row => 3, -column => 2, );
        $mass_check -> select;

        $frame_ent1 -> Label( -text => 'Stride (step) between frames: ', )
                              -> grid( -row => 1, -column => 1, );
        $frame_ent1 -> Entry( -textvariable => \$ent_step, )
                              -> grid( -row => 1, -column => 2, );
        $frame_ent1 -> Label( -text => 'Temperature (K): ', )
                              -> grid( -row => 2, -column => 1, );
        $frame_ent1 -> Entry( -textvariable => \$ent_temp, )
                              -> grid( -row => 2, -column => 2, );

        $frame_ent1 -> Checkbutton( -text => 'Automatically create a plot of the results file',
                                       -variable => \$entropy_plot,
                                       -offvalue => 0,
                                       -onvalue => 1, )
                                       -> grid( -row => 3, -column => 1, );

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

                if ( $ent_step and $ent_temp ) {

                    # Make ten repeat runs each time using #
                    # $ent_step more steps. This means in  #
                    # the first run the first tenth of the #
                    # frames will be used, in the second   #
                    # the first fifth...                   #
                    $top_ent -> destroy;

                    $text -> insert( 'end', "\nNow calculating entropy. Running carma with flag :\n", 'valid', );
                    $text -> see( 'end', );
                    $mw -> update;

                    # The result of the $i * $ent_step     #
                    # multiplication is the number of the  #
                    # frame that will be used after the    #
                    # ' -last' flag                        #
                    for ( my $i = 0 ; ( $i * $ent_step ) < $frames ; $i++ ) {

                        # If that number exceeds the number of #
                        # frames in the .dcd header then that  #
                        # number will be used instead          #
                        if ( ( $frames - ( $i * $ent_step ) ) > $ent_step ) {

                            $lower_ent_limit = 1;
                            $upper_ent_limit = ( ( $i + 1 ) * $ent_step );
                            $text -> insert( 'end', "\nCalculating entropy for frames $lower_ent_limit - $upper_ent_limit :\n", 'valid' );
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
                            $upper_ent_limit = $frames;
                            $text -> insert( 'end', "\nCalculating entropy for frames $lower_ent_limit - $upper_ent_limit :\n", 'valid' );
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
                        open READ_ENTROPY, '<' , "carma.out.copy" || die "Cannot open carma.out.copy for reading:$!";
                        open WRITE_ENTROPY, '>>', "carma_entropy.dat" || die "Cannot open carma_entropy.dat for writing:$!";

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

                        if ( $upper_ent_limit == $frames ) {

                            if ( $all_done ) {

                                $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
                                $text -> see( 'end', );
                                $image_menu -> configure( -state => 'normal', );
                            }
                            else {

                                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                                $text -> insert( 'end', getcwd . "\n", 'info', );
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

                        open WRITE_ENTROPY, '>', "carma_entropy.dat" || die "Cannot open carma_entropy.dat for writing";
                        my $k = 0;
                        foreach ( @s_entropy ) {

                            $k++;
                        }

                        for ( my $j = 0 ; $j < $k ; $j++ ) {

                            printf WRITE_ENTROPY ( "%3d %15.5f %15.5f\n", $j + 1, $a_entropy[$j], $s_entropy[$j], );
                        }
                        close WRITE_ENTROPY;
                    }

                    if ( $entropy_plot ) {

                        plot ( 'carma_entropy.dat' );
                        $entropy_plot = 0;
                    }
                }
                else {

                    $top_ent -> messageBox( -message => 'Both step and temperature need to be defined for entropy calculation',
                                            -icon => 'warning', );
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

    my $top_pdb;
    my $pdb_step;
    my $pdb_step_flag;
    my $pdb_first = 1;
    my $pdb_first_flag = '';
    my $pdb_last = dcd_header_parser( "pdb" );
    my $pdb_last_flag = '';

    if ( !Exists ( $top_pdb ) ) {

        if ( $pdb_last > 500 ) {

            $pdb_step = int ( ( $pdb_last / 500 ) + 0.5 );
        } else {

            $pdb_step = 1;
        }

        $top_pdb = $mw -> Toplevel( -title => 'Extract selected PDB files', );
        $top_pdb -> geometry("$toplevel_position");
        $top_pdb -> protocol( 'WM_DELETE_WINDOW' => sub { $top_pdb -> withdraw }, );

        my $frame_pdb1 = $top_pdb -> Frame() -> pack( -fill => 'x', );
        my $frame_pdb2 = $top_pdb -> Frame() -> pack( -fill => 'x', );
        my $frame_pdb3 = $top_pdb -> Frame() -> pack( -fill => 'x', );
        my $frame_pdb4 = $top_pdb -> Frame() -> pack( -fill => 'x', );

        &radiobuttons ( $frame_pdb2 );
        &checkbuttons ( $frame_pdb3 );
        &otherbuttons ( $frame_pdb4 );

        $frame_pdb1 -> Label( -text => 'Stride (step) between frames: ', )
                              -> grid( -row => 1, -column => 1, );
        $frame_pdb1 -> Entry( -textvariable => \$pdb_step, )
                              -> grid( -row => 1, -column => 2, );
        $frame_pdb1 -> Label( -text => 'First frame to use: ', )
                              -> grid( -row => 2, -column => 1, );
        $frame_pdb1 -> Entry( -textvariable => \$pdb_first, )
                              -> grid( -row => 2, -column => 2, );
        $frame_pdb1 -> Label( -text => 'Last frame to use: ', )
                              -> grid( -row => 3, -column => 1, );
        $frame_pdb1 -> Entry( -textvariable => \$pdb_last, )
                              -> grid( -row => 3, -column => 2, );

        my $frame_pdb5 = $top_pdb -> Frame() -> pack( -expand => 0, );

        $frame_pdb5 -> Button( -text => 'Return',
                               -command => [ $top_pdb => 'withdraw' ], )
                               -> pack( -side => 'left', );

        $frame_pdb5 -> Button( -text => 'Run',
                               -command => sub {

        $pdb_first_flag = ( ( $pdb_first != 1 ) ? " -first $pdb_first" : '' );
        $pdb_last_flag = ( ( $pdb_last != $header ) ? " -last $pdb_last" : '' );
        $pdb_step_flag = ( ( $pdb_step != 1 ) ? " -step $pdb_step" : '' );

        $top_pdb -> destroy;

		$seg_id_flag = '' if $seg_id_flag;

		foreach ( @seg_ids ) {

			if ( defined ( $_ ) ) {

				$seg_id_flag = $seg_id_flag . $_;
			}
		}

		if ( $seg_id_flag ) {

			$flag = " -v -w -pdb $pdb_step_flag $pdb_first_flag $pdb_last_flag $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
		}
		else {

			$flag = " -v -w -pdb $pdb_step_flag $pdb_first_flag $pdb_last_flag $atm_id_flag $custom_id_flag $res_id_flag";
		}
        &create_dir;

        $text -> insert( 'end', "\nNow extracting pdb files. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;
        if ( $all_done ) {

            $text -> insert( 'end', "\nCalculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
            $text -> see( 'end', );
        }
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

    my $rms_first = 1;
    my $rms_first_flag = '';
    my $rms_last = dcd_header_parser( "rms" );
    my $rms_last_flag = '';
    my $rms_step = 1;
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

        $frame_rms4 -> Label( -text => 'First frame to use: ', )
                              -> grid( -row => 1, -column => 1, );
        $frame_rms4 -> Entry( -textvariable => \$rms_first, )
                              -> grid( -row => 1, -column => 2, );
        $frame_rms4 -> Label( -text => 'Last frame to use: ', )
                              -> grid( -row => 2, -column => 1, );
        $frame_rms4 -> Entry( -textvariable => \$rms_last, )
                              -> grid( -row => 2, -column => 2, );
        $frame_rms4 -> Label( -text => 'Stride (step) between frames: ', )
                              -> grid( -row => 3, -column => 1, );
        $frame_rms4 -> Entry( -textvariable => \$rms_step, )
                              -> grid( -row => 3, -column => 2, );

        $frame_rms4 -> Label( -text => 'Minimum value for postscript plot (dark blue): ', )
                              -> grid( -row => 1, -column => 3, );
        $frame_rms4 -> Entry( -textvariable => \$rms_min, )
                              -> grid( -row => 1, -column => 4, );
        $frame_rms4 -> Label( -text => 'Maximum value for postscript plot (dark red): ', )
                              -> grid( -row => 2, -column => 3, );
        $frame_rms4 -> Entry( -textvariable => \$rms_max, )
                              -> grid( -row => 2, -column => 4, );
        $frame_rms4 -> Label( -text => 'Mrms: ', )
                              -> grid( -row => 3, -column => 3, );
        $frame_rms4 -> Entry( -textvariable => \$rms_mrms, )
                              -> grid( -row => 3, -column => 4, );

        $frame_rms4 -> Checkbutton( -text => 'Reverse color gradient',
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

        $rms_first_flag = ( ( $rms_first != 1 ) ? " -first $rms_first" : '' );
        $rms_last_flag = ( ( $rms_last != $header ) ? " -last $rms_last" : '' );
        $rms_step_flag = ( ( $rms_step != 1 ) ? " -step $rms_step" : '' );
        $rms_min_flag = ( $rms_min ? " -min $rms_min" : '' );
        $rms_max_flag = ( $rms_max ? " -max $rms_max" : '' );
        $rms_mrms_flag = ( $rms_mrms ? " -mrms $rms_mrms" : '' );

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

        $text -> insert( 'end', "\nNow calculating average Ca - Ca distances. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            open RMS_OUT, "carma.out.copy" || die "Cannot open carma.out.copy for reading: $!";
            while ( <RMS_OUT> ) {

                if ( /Writing postscript file (\w*\.dcd\.averag.ps)/ ) {

                    $average_ps_file = $1;
                }
                if ( /Writing postscript file (\w*\.dcd\.rmsdev.ps)/ ) {

                    $rmsdev_ps_file = $1;
                }
            }
            close RMS_OUT;

            if ( $linux || $mac ) {

                `carma $average_ps_file $rmsdev_ps_file`;
            }
            else {

                `carma.exe $average_ps_file $rmsdev_ps_file`;
            }

            $text -> insert( 'end', "Calculation finished. Use \'View Results\'\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
            $text -> see( 'end', );
        }
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

        $text -> insert( 'end', "\nNow calculating radious of gyration. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
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

    my ( @list, ) = helper_function();

    if ( !Exists ( $top_dis ) ) {

        $top_dis = $mw -> Toplevel( -title => 'Distances', );
        $top_dis -> geometry("$toplevel_position");
        $top_dis -> protocol( 'WM_DELETE_WINDOW' => sub { $top_dis -> withdraw }, );

        my $frame_dis0 = $top_dis -> Frame() -> pack;
        my $frame_dis1 = $top_dis -> Frame() -> pack;

        $frame_dis0 -> Label( -text => 'Define atoms by selecting resiue number, chain identifier and atom type', ) -> pack;

        our $dist_list1 = $frame_dis1 -> BrowseEntry( -label => 'Atom 1 :',
                                                      -variable => \$dis_atom1,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $dist_list1 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $dis_atom1 = $1;
            }
        }, ) -> grid( -row => 2, -column => 1, );
        our $dist_list2 = $frame_dis1 -> BrowseEntry( -label => 'Atom 2 :',
                                                      -variable => \$dis_atom2,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $dist_list2 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $dis_atom2 = $1;
            }
        }, ) -> grid( -row => 2, -column => 2, );


        $dist_list1 -> insert( 'end', @list, );
        $dist_list2 -> insert( 'end', @list, );

        our $frame_dis2 = $top_dis -> Frame() -> pack( -fill => 'x', );
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

        $text -> insert( 'end', "\nNow calculating distances. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
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

    my ( @list, ) = helper_function();

    if ( !Exists ( $top_bnd ) ) {

        $top_bnd = $mw -> Toplevel( -title => 'Bending angles', );
        $top_bnd -> geometry("$toplevel_position");
        $top_bnd -> protocol( 'WM_DELETE_WINDOW' => sub { $top_bnd -> withdraw }, );

        my $frame_bnd0 = $top_bnd -> Frame() -> pack;
        my $frame_bnd1 = $top_bnd -> Frame() -> pack;

        $frame_bnd0 -> Label( -text => 'Define atoms by selecting resiue number, chain identifier and atom type', ) -> pack;

        our $bend_list1 = $frame_bnd1 -> BrowseEntry( -label => 'Atom 1 :',
                                                      -variable => \$bnd_atom1,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $bend_list1 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $bnd_atom1 = $1;
            }
        }, ) -> grid( -row => 2, -column => 1, );
        our $bend_list2 = $frame_bnd1 -> BrowseEntry( -label => 'Atom 2 :',
                                                      -variable => \$bnd_atom2,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $bend_list2 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $bnd_atom2 = $1;
            }
        }, ) -> grid( -row => 2, -column => 2, );
        our $bend_list3 = $frame_bnd1 -> BrowseEntry( -label => 'Atom 3 :',
                                                      -variable => \$bnd_atom3,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $bend_list3 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $bnd_atom3 = $1;
            }
        }, ) -> grid( -row => 2, -column => 3, );

        $bend_list1 -> insert( 'end', @list, );
        $bend_list2 -> insert( 'end', @list, );
        $bend_list3 -> insert( 'end', @list, );

        our $frame_bnd2 = $top_bnd -> Frame() -> pack( -fill => 'x', );
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

        $text -> insert( 'end', "\nNow calculating bend angles. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
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

    my @list = helper_function();
    #~ foreach ( @list ) { print "$_\n";};

    if ( !Exists ( $top_tor ) ) {

        $top_tor = $mw -> Toplevel( -title => 'Torsion angles', );
        $top_tor -> geometry("$toplevel_position");
        $top_tor -> protocol( 'WM_DELETE_WINDOW' => sub { $top_tor -> withdraw }, );

        my $frame_tor0 = $top_tor -> Frame() -> pack;
        my $frame_tor1 = $top_tor -> Frame() -> pack;

        $frame_tor0 -> Label( -text => 'Define atoms by selecting resiue number, chain identifier and atom type', ) -> pack;

        our $tors_list1 = $frame_tor1 -> BrowseEntry( -label => 'Atom 1 :',
                                                      -variable => \$tor_atom1,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $tors_list1 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $tor_atom1 = $1;
            }
        }, ) -> grid( -row => 2, -column => 1, );
        our $tors_list2 = $frame_tor1 -> BrowseEntry( -label => 'Atom 2 :',
                                                      -variable => \$tor_atom2,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $tors_list2 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $tor_atom2 = $1;
            }
        }, ) -> grid( -row => 2, -column => 2, );
        our $tors_list3 = $frame_tor1 -> BrowseEntry( -label => 'Atom 3 :',
                                                      -variable => \$tor_atom3,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $tors_list3 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $tor_atom3 = $1;
            }
        }, ) -> grid( -row => 2, -column => 3, );
        our $tors_list4 = $frame_tor1 -> BrowseEntry( -label => 'Atom 1 :',
                                                      -variable => \$tor_atom4,
                                                      -listwidth => 36,
                                                      -autolistwidth => 0,
                                                      -browsecmd => sub {

            my $selection = our $tors_list4 -> get( 'active' );

            if ( $selection =~ /(\d+)$/ ) {

                $tor_atom4 = $1;
            }
        }, ) -> grid( -row => 2, -column => 4, );

        $tors_list1 -> insert( 'end', @list, );
        $tors_list2 -> insert( 'end', @list, );
        $tors_list3 -> insert( 'end', @list, );
        $tors_list4 -> insert( 'end', @list, );

        our $frame_tor2 = $top_tor -> Frame() -> pack( -fill => 'x', );
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

        $text -> insert( 'end', "\nNow calculating torsion angles. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
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
###   Helper function for the distances, bending and torsion angles functions                   ###
###################################################################################################

sub helper_function {

    create_dir();

    my ( @atom_data, );

    if ( $linux or $mac ) {

        `carma -w -last 1 $atm_id_flag $custom_id_flag $active_psf $active_dcd`;
    }
    else {

        `carma.exe -w -last 1 $atm_id_flag $custom_id_flag $active_psf $active_dcd`;
    }

    unlink ( "$active_dcd.0000001.dat", "$active_dcd.0000001.ps" );

    open IN, '<', "carma.selected_atoms.psf" or die "Cannot open carma.selected_atoms.psf for reading: $!";

    my $i = 0;
    my $num_of_atoms = 0;
    while ( <IN> ) {

        if ( /(\d+) !NATOM/ ) {

            $num_of_atoms = $1;
            last;
        }
    }

    while ( <IN> ) {

        my ( $segid, $atmid, $resid, $atmnum);

        $resid = substr $_, 14, 4;
        $segid = substr $_, 9, 1;
        $atmid = substr $_, 24, 4;
        $atmnum = substr $_, ( 8 - length $num_of_atoms ), length $num_of_atoms;

        $atom_data[$i] = sprintf ( "%04d %s % 3s %7d", $resid, $segid, $atmid, $atmnum, );
        $i++;
    }

    close IN;

    return ( @atom_data, );
}

###################################################################################################
###   Draw the window for phi/psi dihedral angles                                               ###
###################################################################################################

sub phi_psi_window {

    my $top_phi_psi;

    if ( !Exists ( $top_phi_psi ) ) {

        $top_phi_psi = $mw -> Toplevel( -title => 'phi/psi dihedral angles', );
        $top_phi_psi -> geometry("$toplevel_position");
        $top_phi_psi -> protocol( 'WM_DELETE_WINDOW' => sub { $top_phi_psi -> withdraw }, );

        $frame_phi_psi1 = $top_phi_psi -> Frame() -> pack( -fill => 'x', );
        my $frame_phi_psi2 = $top_phi_psi -> Frame() -> pack( -fill => 'x', );
        my $frame_phi_psi3 = $top_phi_psi -> Frame() -> pack( -expand => 0, );
        my $frame_phi_psi4 = $top_phi_psi -> Frame() -> pack( -fill => 'x', );

        checkbuttons ( $frame_phi_psi1 );
        #~ otherbuttons ( $frame_phi_psi2 );

        $frame_phi_psi3 -> Button( -text => 'Return',
                               -command => [ $top_phi_psi => 'withdraw' ], )
                               -> pack( -side => 'left', );

        $phi_psi_run_button = $frame_phi_psi3 -> Button( -text => 'Run',
                                                         -state => 'disabled',
                                                         -command => sub {

            $top_phi_psi -> destroy;

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            &create_dir;

            our $temp_segid;
            if ( $seg_id_flag =~ /([A-Z])/ ) {

                $temp_segid = $1;
            }
            our ( $first_residue, $last_residue, $number_of_residues, $correction, ) = indeces ( "$temp_segid" );

            $flag = " -v -atmid ALLID -torsion indeces.dat";

            $text -> insert( 'end', "\nNow calculating phi/psi dihedral angles. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma;

            if ( $all_done ) {

                mv ( "carma.torsions", "phi_psi_dihedral_segid$temp_segid.dat" );

                $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
                $text -> see( 'end', );
                $image_menu -> configure( -state => 'normal', );
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
                $text -> see( 'end', );
            }
        }, )-> pack( -side => 'right', );

        if ( $active_run_buttons_qfract ) {

            $phi_psi_run_button -> configure( -state => 'normal', );
        }
        else {

            $phi_psi_run_button -> configure( -state => 'disabled', );
        }
    }
    else {

        $top_phi_psi -> deiconify;
        $top_phi_psi -> raise;
    }
}

###################################################################################################
### Get the atom indeces for calculating phi/psi angles                                         ###
### Contributed by N. M. Glykos                                                                 ###
###################################################################################################

sub indeces {

    my $input = shift;

    my (
        $nofatm, $tot, @at,
        $at1_num, $at1_res, $at1_nam,
        $at2_num, $at2_res, $at2_nam,
        $at3_num, $at3_res, $at3_nam,
        $at4_num, $at4_res, $at4_nam,
        $is_C, $is_CA, $is_N,
        $index1, $index2, );

    open OUT, '+>', 'temp.dat' or die "cannot open indeces.dat for writing : $!\n";
    open IN, '<', $active_psf or die "cannot open $active_psf for reading : $!\n";

    while ( <IN> ) {

        if ( /(\d+) !NATOM/ ) {

            $nofatm = $1;
            last;
        }
    }

    $tot = 0;
    for ( my $i = 0 ; $i < $nofatm  ; $i++ ) {

        my $line = <IN>;
        if ( $line =~ /(\d+)\s+$input\s+(\d+)\s+\w+\s+(\w+)/ ) {

            if ( $3 eq "N" || $3 eq "C" || $3 eq "CA" ) {

                $at[ $tot ] = $1 . " " . $2 . " " . $3;
                $tot++;
            }
        }
        #~ else {
            #~
            #~ die "Unexpected line in PSF. Giving up ...\n$line\n";
        #~ }
    }

    #~ print "Found $tot N-CA-C atoms ...\n";

    if ( $tot % 3 != 0 ) {

        die "Unexpected number of residues. Abort.\n";
    }
    if ( $tot == 0 ) {

        die "No C CA N atoms found in the psf. Abort.\n";
    }

    for ( my $i=0 ; $i < $tot ; $i += 3 ) {

        if ( $at[ $i ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at1_num = $1;
            $at1_res = $2;
            $at1_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at[ $i+1 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at2_num = $1;
            $at2_res = $2;
            $at2_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at[ $i+2 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at3_num = $1;
            $at3_res = $2;
            $at3_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at2_res ne $at1_res || $at2_res ne $at3_res || $at3_res ne $at1_res ) {

            die "Panic. Get help.\n";
        }

        if ( $at1_nam ne "N" || $at2_nam ne "CA" || $at3_nam ne "C" ) {

            #~ print "Will change order of atoms for residue $at2_res\n";

            if ( $at1_nam eq "N" ) {

                $is_N = 0;
            }
            if ( $at1_nam eq "CA" ) {

                $is_CA = 0;
            }
            if ( $at1_nam eq "C" ) {

                $is_C = 0;
            }

            if ( $at2_nam eq "N" ) {

                $is_N = 1;
            }
            if ( $at2_nam eq "CA" ) {
                $is_CA = 1;
            }
            if ( $at2_nam eq "C" ) {
                $is_C = 1;
            }

            if ( $at3_nam eq "N" ) {
                $is_N = 2;
            }
            if ( $at3_nam eq "CA" ) {
                $is_CA = 2;
            }
            if ( $at3_nam eq "C" ) {
                $is_C = 2;
            }

            my $N_line = $at[ $i + $is_N ];
            my $C_line = $at[ $i + $is_C ];
            my $CA_line = $at[ $i + $is_CA ];

            $at[ $i   ] = $N_line;
            $at[ $i+1 ] = $CA_line;
            $at[ $i+2 ] = $C_line;
        }
    }

    for ( my $i=0 ; $i <= ($tot / 3 - 2) ; $i++ ) {

        $index1 = $i * 3;
        $index2 = $i * 3 + 2;

        if ( $at[ $index1 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at1_num = $1;
            $at1_res = $2;
            $at1_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at[ $index1+1 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at2_num = $1;
            $at2_res = $2;
            $at2_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at[ $index1+2 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at3_num = $1;
            $at3_res = $2;
            $at3_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        if ( $at[ $index1+3 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at4_num = $1;
            $at4_res = $2;
            $at4_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        printf OUT "%6d %6d %6d %6d  # psi for residue %4d\n", $at1_num, $at2_num, $at3_num, $at4_num, $at3_res;

        if ( $at[ $index2 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at1_num = $1;
            $at1_res = $2;
            $at1_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }
        if ( $at[ $index2+1 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at2_num = $1;
            $at2_res = $2;
            $at2_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }
        if ( $at[ $index2+2 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at3_num = $1;
            $at3_res = $2;
            $at3_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }
        if ( $at[ $index2+3 ] =~ /(\d+) (\d+) (\w+)/ ) {

            $at4_num = $1;
            $at4_res = $2;
            $at4_nam = $3;
        }
        else {

            die "Something is wrong. Get help.\n";
        }

        printf OUT "%6d %6d %6d %6d  # phi for residue %4d\n", $at1_num, $at2_num, $at3_num, $at4_num, $at4_res;
    }
    seek OUT, 0, 0;

    open OUT2, '+>', 'indeces.dat' or die "Cannot open indeces.dat for writing : $!\n";

    while ( <OUT> ) {

		print OUT2 $_ unless ( $. == 1 or eof );
	}
	unlink ( 'temp.dat', );

	seek OUT2, 0, 0;

	my @resid_span;
	my $i = 0;
	while ( <OUT2> ) {

		if ( /p.i for residue\s+(\d+)/ ) {

			$resid_span[$i] = $1;
			$i++;
		}
	}

	my $first_residue = $resid_span[0];
	my $last_residue = $resid_span[scalar @resid_span - 1];
	my $num_residues = ( scalar @resid_span / 2 );
	my $correction = 0;
	if ( $first_residue != 2 ) {

		$correction = $first_residue - 2;
	}

    close OUT2;
    close IN;
    close OUT;

    return ( $first_residue, $last_residue, $num_residues, $correction, );
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

            $text -> insert( 'end', "\nNow mapping water and ions. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma;

            if ( $all_done ) {

                $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
                $text -> see( 'end', );
                $image_menu -> configure( -state => 'normal', );
            }
            else {

                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
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

                $filetype = [ ['Fitting index files', '.index'], ['Fitting index files',  '.index'] ];
            }

            my $file = $mw -> getOpenFile( -filetypes => $filetype, );

            if ( $file =~ /\w*\.index/ ) {

                $file = abs_path ( $file );
                &create_dir;

                if ( $linux || $mac ) {

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
    my $sur_plot = '';

    if ( !Exists ( $top_sur ) ) {

        $top_sur = $mw -> Toplevel( -title => 'Surface area', );
        $top_sur -> geometry("$toplevel_position");
        $top_sur -> protocol( 'WM_DELETE_WINDOW' => sub { $top_sur -> withdraw }, );

        my $frame_sur1 = $top_sur -> Frame() -> pack( -fill => 'x', );
        $frame_sur2 = $top_sur -> Frame() -> pack( -fill => 'x', );
        my $frame_sur3 = $top_sur -> Frame() -> pack( -fill => 'x', );
        my $frame_sur5 = $top_sur -> Frame() -> pack( -fill => 'x', );

        &radiobuttons ( $frame_sur1 );
        &checkbuttons ( $frame_sur2 );
        &otherbuttons ( $frame_sur3 );

        $frame_sur5 -> Label( -text => 'Various options', ) -> pack;

        $frame_sur5 -> Checkbutton( -text => 'Automatically create a plot of the results file',
                                    -variable => \$sur_plot,
                                    -offvalue => 0,
                                    -onvalue => 1, )
                                    -> pack( -side => 'top', -anchor => 'w', );

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

        $text -> insert( 'end', "\nNow calculating surface area. Running carma with flag :\n", 'valid', );
        $text -> see( 'end', );
        $mw -> update;

        &carma;

        if ( $all_done ) {

            $text -> insert( 'end', "Calculation finished. Use \"View Results\"\n", 'valid' );
            $text -> see( 'end', );
            $image_menu -> configure( -state => 'normal', );

            if ( $sur_plot ) {

                &plot ( 'carma.surface.dat' );
                $sur_plot = 0;
            }
        }
        else {

            $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
            $text -> insert( 'end', getcwd . "\n", 'info', );
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
    my $fit_plot = '';
    my $index = '';
    my $index_confirmation = '';
    my $fit_run_button;

    my $index_atm_id;
    my $index_atm_id_flag;
    my $index_seg_id_flag;
    my $index_res_id_flag;
    my @index_seg_ids;

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
        my $frame_fit5 = $top_fit -> Frame() -> pack( -fill => 'x', );

        $index_bar_count = 0;
        $frame_fit6[$index_bar_count] = $top_fit -> Frame() -> pack();
        $frame_fit_bars[$index_bar_count] = $top_fit -> Frame();

        my $frame_fit6a = $frame_fit6[0] -> Frame() -> grid( -row => 0, -column => 2, -columnspan => 6, );

##########################################################################################################

        #~ $frame_fit6a -> Label( -text => "\nATOMS TO USE FOR THE FITTING\n", -font => "$font_20", )
                               #~ -> grid( -row => 0, -column => 2, );

        $frame_fit6a -> Label( -text => 'Atmid Selection' ) -> grid( -row => 1, -column => 2, );

        my @index_radiobuttons = ( 'CA', 'Backbone', 'Heavy', 'All atoms', 'Custom selection', );
        my @index_radio_b;

        for my $i ( 0 .. $#index_radiobuttons ) {

            $index_radio_b[$i] = $frame_fit6a -> Radiobutton( -text => $index_radiobuttons[$i],
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

                &create_dir;

                if ( $linux || $mac ) {

                    $seg_id_flag = '' if $seg_id_flag;

                    foreach ( @seg_ids ) {

                        if ( defined ( $_ ) ) {

                            $seg_id_flag = $seg_id_flag . $_;
                        }
                    }

                    if ( $seg_id_flag ) {

                        `carma -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd`;
                    }
                    else {

                        `carma -v -w -last 1 $atm_id_flag $custom_id_flag $res_id_flag $active_psf $active_dcd`;
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

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd"`;
                    }
                    else {

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $active_psf $active_dcd`;
                    }
                }

                unlink ( "$dcd_name.dcd.0000001.dat" );
                unlink ( "$dcd_name.dcd.0000001.ps" );

                $index_seg_id_flag = '' if $index_seg_id_flag;

                foreach ( @index_seg_ids ) {

                    if ( defined ( $_ ) ) {

                        $index_seg_id_flag = $index_seg_id_flag . $_;
                    }
                }
                
                if ( $index_seg_id_flag ) {

                    create_fit_index( $index_atm_id, 'from_radiobutton', $index_seg_id_flag, );
                }
                else {
                    
                    create_fit_index( $index_atm_id, 'from_radiobutton', );
                }

                $index = ' -index';
                $index_confirmation = 1;

                $fit_run_button -> configure( -state => 'normal', );
            }, );

            $index_radio_b[$i] -> grid( -row => 2, -column => $i, );
        }

        $index_radio_b[4] -> configure( -command => \&raise_custom_window, );

        $frame_fit6a -> Label( -text => "Segid Selection", ) -> grid( -row => 3, -column => 2, );

        my @index_check_b;

        my $index_count = 0;

        for my $j ( 0 .. $#unique_chain_ids ) {

            $index_check_b[$j] = $frame_fit6a -> Checkbutton( -text => $unique_chain_ids[$j],
                                                              -variable => \$index_seg_ids[$j],
                                                              -offvalue => '',
                                                              -onvalue => "$unique_chain_ids[$j]",
                                                              -command => sub {
             
                &create_dir;

                if ( $linux || $mac ) {

                    $seg_id_flag = '' if $seg_id_flag;

                    foreach ( @seg_ids ) {

                        if ( defined ( $_ ) ) {

                            $seg_id_flag = $seg_id_flag . $_;
                        }
                    }

                    if ( $seg_id_flag ) {

                        `carma -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd`;
                    }
                    else {

                        `carma -v -w -last 1 $atm_id_flag $custom_id_flag $res_id_flag $active_psf $active_dcd`;
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

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd"`;
                    }
                    else {

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $active_psf $active_dcd`;
                    }
                }

                unlink ( "$dcd_name.dcd.0000001.dat" );
                unlink ( "$dcd_name.dcd.0000001.ps" );

                $index_seg_id_flag = '' if $index_seg_id_flag;

                foreach ( @index_seg_ids ) {

                    if ( defined ( $_ ) ) {

                        $index_seg_id_flag = $index_seg_id_flag . $_;
                    }
                }
                
                if ( $index_seg_id_flag ) {

                    create_fit_index( $index_atm_id, 'from_radiobutton', $index_seg_id_flag, );
                }
                else {
                    
                    create_fit_index( $index_atm_id, 'from_radiobutton', );
                }

                $index = ' -index';
                $index_confirmation = 1;

                $fit_run_button -> configure( -state => 'normal', );
            }, );

            $index_check_b[$j] -> grid( -row => 4, -column => $j, );
        }

        my @index_otherbuttons = ( 'All', 'Change', );
        my @index_other;

        $frame_fit6a -> Label( -text => 'Resid Selection', ) -> grid( -row => 5, -column => 2, );

        for my $k ( 0 .. $#index_otherbuttons ) {

            $index_other[$k] = $frame_fit6a -> Radiobutton( -text => "$index_otherbuttons[$k]",
                                                            -value => $index_otherbuttons[$k],
                                                            -variable => \$index_res_id_flag, );

            $index_other[$k] -> grid( -row => 6, -column => $k, );
        }

####################################################################################################
        #~ $frame_fit6[0] -> Label( -text => "\n", )
                                 #~ -> grid ( -row => 0, -column => 3, );

        $frame_fit_bars[0] -> Button( -text => 'Confirm',
                                  -width => 10,
                                  -command => sub {

            my $i;
            my $check = 0;
            for ( $i = 1 ; $i <= $index_bar_count ; $i++ ) {

                if ( $lower_fit_limit[$i-1] and $upper_fit_limit[$i-1] and $fit_drop_value[$i-1] ) {

                    $check++;
                }
            }

            if ( $check == $i - 1 ) {

                &create_dir;

                if ( $linux || $mac ) {

                    $seg_id_flag = '' if $seg_id_flag;

                    foreach ( @seg_ids ) {

                        if ( defined ( $_ ) ) {

                            $seg_id_flag = $seg_id_flag . $_;
                        }
                    }

                    if ( $seg_id_flag ) {

                        `carma -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd`;
                    }
                    else {

                        `carma -v -w -last 1 $atm_id_flag $custom_id_flag $res_id_flag $active_psf $active_dcd`;
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

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $seg_id_flag $active_psf $active_dcd"`;
                    }
                    else {

                        `carma.exe -v -w -last 1 $atm_id_flag $res_id_flag $custom_id_flag $active_psf $active_dcd`;
                    }
                }

                unlink ( "$dcd_name.dcd.0000001.dat" );
                unlink ( "$dcd_name.dcd.0000001.ps" );

                $index_seg_id_flag = '' if $index_seg_id_flag;

                foreach ( @index_seg_ids ) {

                    if ( defined ( $_ ) ) {

                        $index_seg_id_flag = $index_seg_id_flag . $_;
                    }
                }
                
                if ( $index_seg_id_flag ) {

                    create_fit_index( $index_atm_id, 'from_confirm', $index_seg_id_flag, );
                }
                else {
                    
                    create_fit_index( $index_atm_id, 'from_confirm', );
                }

                $index = ' -index';
                $index_confirmation = 1;

                $fit_run_button -> configure( -state => 'normal', );
            }
            else {

                $top_fit -> messageBox( -message => 'All of the boxes must be filled in order to submit a residue selection',
                                        -icon => 'warning', );
            }
        }, ) -> grid( -row => 1, -column => 7, );

        $frame_fit6[0] -> packForget;

        $frame_fit_bars[$index_bar_count] -> Button( -text => 'Add..',
                                                 -width => 10,
                                                 -command => sub {

            $frame_fit_bars[$index_bar_count] = $top_fit -> Frame() -> pack( -anchor => 'w', );# unless ( $index_bar_count == 0 );

            &add_index_bar;

            foreach ( keys %num_residues ) {

                $fit_drop[$index_bar_count] -> insert( 'end', $_ );
            }

            if ( $index_bar_count >= 1 ) {

                $frame_fit_bars[$index_bar_count] -> Button( -text => 'Remove',
                                                         -width => 10,
                                                         -command => sub {

                    $frame_fit_bars[$index_bar_count-1] -> destroy;
                    $index_bar_count--;
				}, ) -> grid( -row => "$index_row", -column => "$index_column" + 5, );
			}

			$index_bar_count++;
		}, ) -> grid( -row => 1, -column => 6, );

        $index_other[0] -> configure( -command => sub {

            if ( $index_bar_count != 0 ) {

                for ( my $i = $index_bar_count ; $i > 0 ; $i-- ) {

                    $frame_fit_bars[$i-1] -> packForget;
                    $index_bar_count--;
                }
            }
        } );
        $index_other[0] -> invoke;

        $index_other[1] -> configure( -command => sub {

            if ( $index_bar_count == 0 ) {

                add_index_bar();
                $frame_fit_bars[$index_bar_count] -> pack( -anchor => 'w', );
                $index_bar_count++;
            }
        }, );

        my $index_row = 1;
        my $index_column = 4;

        #&add_index_bar;

        &radiobuttons ( $frame_fit1 );
        &checkbuttons ( $frame_fit2 );
        &otherbuttons ( $frame_fit3 );

        my $frame_fit2a = $top_fit -> Frame() -> pack( -fill => 'x', );
        my $frame_fit4 = $top_fit -> Frame() -> pack( -fill => 'x', );

        $frame_fit2a -> Label( -text => 'Optional settings', -font => "$font_20", )
                               -> pack( -side => 'bottom', );

        my $index_bool;
        my $index_button = $frame_fit4 -> Checkbutton( -text => 'Perform selective fitting',
                                                       -variable => \$index_bool,
                                                       -command => sub {

            if ( $fit_run_button -> cget( -state, ) eq 'normal' and not $index_confirmation ) {

                $fit_run_button -> configure( -state => 'disabled', );
            }
            elsif ( $fit_run_button -> cget( -state, ) eq 'disabled' ) {

                $fit_run_button -> configure( -state => 'normal', );
            }

            if ( $index_bool ) {

                $frame_fit6[0] -> pack;
            }
            else {

                for ( my $i = 0 ; $i <= $index_bar_count ; $i++ ) {

                    $frame_fit6[$i] -> packForget;
                }
            }
        }, ) -> grid( -row => 4, -column => 1, -sticky => 'w', );

        my $ref_fit_entry = $frame_fit4 -> Entry( -textvariable => \$ref_atom_num,
                                                  -state => 'disabled', )
                                                  -> grid( -row => 2, -column => 2, -sticky => 'w', );

        $frame_fit4 -> Checkbutton( -text => 'Automatically create a plot of the results file',
                                    -variable => \$fit_plot,
                                    -offvalue => 0,
                                    -onvalue => 1, )
                                    -> grid( -row => 1, -column => 1, -sticky => 'w', );

        $frame_fit4 -> Checkbutton( -text => "Use frame as ref: ",
                                    -variable => \$ref,
                                    -offvalue => '',
                                    -onvalue => " -ref",
                                    -command => sub { $ref_fit_entry -> configure( -state => 'normal', ); }, )
                                    -> grid( -row => 2, -column => 1, -sticky => 'w', );

        $frame_fit4 -> Checkbutton( -text => 'No fit',
                                    -variable => \$no_fit,
                                    -offvalue => '',
                                    -onvalue => " -nofit", )
                                    -> grid( -row => 3, -column => 1, -sticky => 'w', );

        my $frame_fit7 = $top_fit -> Frame() -> pack( -side => 'bottom', -expand => 0, );

        $frame_fit7 -> Button( -text => 'Return',
                               -command => sub { $top_fit -> withdraw; }, )
                               -> pack( -side => 'left', );

        $fit_run_button = $frame_fit7 -> Button( -text => 'Run',
                                                 -command => sub {

            $top_fit -> destroy;

            $seg_id_flag = '' if $seg_id_flag;

            foreach ( @seg_ids ) {

                if ( defined ( $_ ) ) {

                    $seg_id_flag = $seg_id_flag . $_;
                }
            }

            if ( $seg_id_flag ) {

                $flag = " -w -v -fit $ref $index $ref_atom_num $no_fit $atm_id_flag $custom_id_flag $res_id_flag $seg_id_flag";
            }
            else {

                $flag = " -w -v -fit $ref $index $ref_atom_num $no_fit $atm_id_flag $custom_id_flag $res_id_flag";
            }

            &create_dir;

            $text -> insert( 'end', "\nNow performing fitting. Running carma with flag :\n", 'valid', );
            $text -> see( 'end', );
            $mw -> update;

            &carma ( "fit" );
            if ( $all_done ) {

                $text -> insert( 'end', "Fitting complete. Use \"View Results\"\n", 'valid' );
                $text -> see( 'end', );
                $image_menu -> configure( -state => 'normal', );

                my $response = $mw -> messageBox( -message => "Would you like to use this PSF - DCD pair in other calculations?",
                                                  -type => 'yesno',
                                                  -icon => 'question', );

                if ( $response eq "Yes" ) {

                    $dcd_count++;
                    $active_dcd = "carma.fitted_$dcd_count.dcd";
                    $active_psf = "carma.fitted_$dcd_count.psf";
                    $active_dcd_label -> configure( -text => "Active .dcd: $active_dcd", );
                    $active_psf_label -> configure( -text => "Active .psf: $active_psf", );
                    $go_back_button -> configure( -state => 'normal', );

                    if ( $linux || $mac ) {

                        `mv carma.fitted.dcd carma.fitted_$dcd_count.dcd`;
                        `mv carma.selected_atoms.psf carma.fitted_$dcd_count.psf`;
                    }
                    else {

                        `move carma.fitted.dcd carma.fitted_$dcd_count.dcd`;
                        `move carma.selected_atoms.psf carma.fitted_$dcd_count.psf`;
                    }

                    #~ open PSF, '<', "carma.selected_atoms.psf" or die "Cannot open carma.selected_atoms.psf for reading: $!\n";
                    #~ open OUT, '>', "carma.fitted_$dcd_count.psf" or die "Cannot open carma.fitted_$dcd_count.psf for writing: $!\n";
#~
                    #~ my $line_counter = 1;
                    #~ while ( <PSF> ) {
#~
                        #~ print OUT "$_";
                        #~ if ( /!NATOM/ ) {
#~
                            #~ last;
                        #~ }
                    #~ }
                    #~ while ( <PSF> ) {
#~
                        #~ if ( /(\s+)(\d+)(\s+\w+\s+.+)/ ) {
#~
                            #~ printf OUT ( "%8s%s\n", $line_counter, $3 );
                            #~ $line_counter++;
                        #~ }
                    #~ }
#~
                    #~ close OUT;
                    #~ close PSF;

                }
                else {

                    $mw -> messageBox( -type => "ok",
                                       -message => "These files will not be used in any calculations and will be overwritten next time you perform a fitting", );
                }

                if ( $fit_plot ) {

                    &plot ( 'carma.fit-rms.dat' );
                    $fit_plot = 0;
                }
            }
            else {

                $top_fit -> destroy;
                $text -> insert( 'end', "\nSomething went wrong. For details check carma.out.copy located in :\n", 'error', );
                $text -> insert( 'end', getcwd . "\n", 'info', );
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
###   Create a subfolder in the CWD for the result files                                        ###
###################################################################################################

sub create_dir {

    my $input;
    if ( $_[0] and $_[0] eq 'stride' ) {

        $input = shift;
    }

    #~ our $new_psf;
    my $abs_path = abs_path($new_psf) if ( $new_psf );

    # If the string returned by the getcwd #
    # function contains the name of the    #
    # folder used for storing the results  #
    # of the program then terminate the    #
    # subroutine with a success status     #
    if ( getcwd =~ /carma_results/ ) {

        unless ( $input and $input eq 'stride' ) {

            return(0);
        }
    }
    # If the folder does not exist in the  #
    # Cwd it is created and a subfolder    #
    # with the current time as it's name   #
    # will be created as well. This folder #
    # will serve as the storing point for  #
    # every grcarma session                #
    # If the folder exists then only the   #
    # subfolder of every session is made   #

    if ( -d -w $launch_dir ) {

        if ( $input and $input eq 'stride' ) {

            mkpath ( "$launch_dir/$timeStamp/tmp", 0, 0755, );
            chdir ( "$launch_dir/$timeStamp/tmp" );
        }
        else {

            mkpath ( "$launch_dir/$timeStamp", 0, 0755, );
            chdir ( "$launch_dir/$timeStamp" );
        }

        # After the folder(s) have been made   #
        # they are made the Cwd and links to   #
        # specified .psf and .dcd files are    #
        # created                              #
        if ( $linux || $mac ) {

            `ln -s $psf_file .`;
            `ln -s $dcd_file .`;
            `ln -s $abs_path .` if ( $new_psf );
        }
        else {

            link ( $psf_file, "$psf_name.psf", );
            link ( $dcd_file, "$dcd_name.dcd", );
            link ( $new_psf, "$psf_name.dcd", );

            `copy ..\\..\\carma.exe .`;
        }
    }
    else {

        if ( $run_from_terminal ) {

            die "\nSeems like you don't have write privileges for the folder the program was launched from: $!\n\n";
        }
        else {

            $mw -> messageBox( -text => "Seems like you don't have write privileges for the folder the program was launched from: $!\n\n",
                               -type => 'ok',
                               -icon => 'warning', );
            $mw -> destroy;
            exit 1;
        }
    }
}

###################################################################################################
###   Create the atmid radiobutton bar                                                          ###
###################################################################################################

sub radiobuttons {

    our $dist_list1;
    our $dist_list2;
    our $frame_dis2;

    our $bend_list1;
    our $bend_list2;
    our $bend_list3;
    our $frame_bnd2;

    our $tors_list1;
    our $tors_list2;
    our $tors_list3;
    our $tors_list4;
    our $frame_tor2;

	our $frame_stride1;

    my $input = shift;
    $input -> Label ( -text => 'Atmid Selection', -font => "$font_20", ) -> pack;

    my @radiobuttons = ( 'CA', 'Backbone', 'Heavy', 'All atoms', 'Custom selection', );
    my @radio_b;

    # For every item of the radiobuttons   #
    # array draw a radiobutton named after #
    # each item and if the radiobutton is  #
    # active store it's name in a variable #
    for my $i ( 0 .. $#radiobuttons ) {

        $radio_b[$i] = $input -> Radiobutton( -text => $radiobuttons[$i],
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

            if ( ( $frame_dis2 ) and $input eq $frame_dis2 ) {

                my ( @temp_list, ) = helper_function();

                $dist_list1 -> delete( 0, 'end' );
                $dist_list2 -> delete( 0, 'end' );

                $dist_list1 -> insert( 'end', @temp_list );
                $dist_list2 -> insert( 'end', @temp_list );
            }
            if ( ( $frame_bnd2 ) and $input eq $frame_bnd2 ) {

                my ( @temp_list, ) = helper_function();

                $bend_list1 -> delete( 0, 'end' );
                $bend_list2 -> delete( 0, 'end' );
                $bend_list3 -> delete( 0, 'end' );

                $bend_list1 -> insert( 'end', @temp_list );
                $bend_list2 -> insert( 'end', @temp_list );
                $bend_list3 -> insert( 'end', @temp_list );
            }
            if ( ( $frame_tor2 ) and $input eq $frame_tor2 ) {

                my ( @temp_list, ) = helper_function();

                $tors_list1 -> delete( 0, 'end' );
                $tors_list2 -> delete( 0, 'end' );
                $tors_list3 -> delete( 0, 'end' );
                $tors_list4 -> delete( 0, 'end' );

                $tors_list1 -> insert( 'end', @temp_list );
                $tors_list2 -> insert( 'end', @temp_list );
                $tors_list3 -> insert( 'end', @temp_list );
                $tors_list4 -> insert( 'end', @temp_list );
            }
        }, );
        if ( $input eq $f2 ) {

            $radio_b[$i] -> pack( -anchor => 'w', );
        }
        else {

            $radio_b[$i] -> pack( -side => 'left', -anchor => 'w', );
        }
    }

	if ( ( $frame_stride1 ) and $input eq $frame_stride1 ) {

		$radio_b[2] -> invoke();
	} else {

		$radio_b[0] -> invoke();
	}

    $radio_b[4] -> configure( -command => \&raise_custom_window);
}

###################################################################################################
###   Create the segid checkbutton bar                                                          ###
###################################################################################################

sub checkbuttons {

    my $input = shift;

    our $frame_rmsd2;

    if ( ( $dpca_frame_1 && $input eq $dpca_frame_1 ) || ( $frame_sur2 && $input eq $frame_sur2 ) ) {

        $input -> Label( -text => 'At least one segid selection required', -font => "$font_20", ) -> pack;
    }
    elsif ( ( $frame_qfract2 && $input eq $frame_qfract2 ) or ( $frame_phi_psi1 and $input eq $frame_phi_psi1 ) ) {

        $input -> Label( -text => 'You must select only one segid', -font => "$font_20", ) -> pack;
    }
    else {

        $input -> Label( -text => 'Segid Selection', -font => "$font_20", ) -> pack;
    }

    my @check_b;

    for my $i ( 0 .. $#unique_chain_ids ) {

        $check_b[$i] = $input -> Checkbutton( -text => $unique_chain_ids[$i],
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

             if ( $seg_ids[$i] ne '' ) {

                 $active_run_buttons = 1;
                 $dpca_run_button -> configure( -state => 'normal', ) if ( $dpca_run_button );
             }
             elsif ( $count < 1 ) {

                 $active_run_buttons = 0;
                 $dpca_run_button -> configure( -state => 'disabled', ) if ( $dpca_run_button );
             }

             if (  $count == 1 ) {

                 $active_run_buttons_qfract = 1;
                 $qfract_run_button -> configure( -state => 'normal', ) if ( $qfract_run_button );
                 $phi_psi_run_button -> configure( -state => 'normal', ) if ( $phi_psi_run_button );
             }
             elsif ( $count != 1 ) {

                 $active_run_buttons_qfract = 0;
                 $qfract_run_button -> configure( -state => 'disabled', ) if ( $qfract_run_button );
                 $phi_psi_run_button -> configure( -state => 'disabled', ) if ( $phi_psi_run_button );
             }
         }, );

        if ( $input eq $f3 ) {

            $check_b[$i] -> pack( -anchor => 'w', );
        }
        else {

            $check_b[$i] -> pack( -side => 'left', -anchor => 'w', );
        }
    }

	if ( ( $frame_rmsd2 ) and $input eq $frame_rmsd2 ) {

        foreach my $element ( @check_b ) {

            if ( $element -> cget( -onvalue, ) =~ /segid (\w+)/ ) {

                if ( length $1 <= 1 ) {

                    $element -> select;
                    $count++;
                }
            }
        }
    }
}

###################################################################################################
###   Create the resid radiobutton bar                                                          ###
###################################################################################################

sub otherbuttons {

    my @otherbuttons = ( 'All', 'Change', );
    my @other;

    $_[0] -> Label( -text => 'Resid Selection', -font => "$font_20", ) -> pack;

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

        if ( $res_id_flag ) {

            $count--;
            $res_id_flag = '';
        }
        $have_custom_psf = 0;
        $f4_b -> destroy if ( $f4_b );
        if ( $dcd_count >= 0 ) {

            $active_psf_label -> configure( -text => "Active .psf: $psf_name.$dcd_count.psf", );
        }
        else {

            $active_psf_label -> configure( -text => "Active .psf: $psf_name.psf", );
        }
        $active_psf = "$psf_name.psf";
    }, );
    $other[1] -> configure( -command => \&resid_window, );
}

###################################################################################################
###   Create the scatter plot of the input file                                                 ###
###################################################################################################

sub scatter_plot {

    open IN, '<', 'phi_psi_temp_angles' or die $!;
	open CONVERTED_ANGLES, '+>', "converted_angles" or die $!;

    while ( my $line = <IN> ) {

        if ( $line =~ /(\s*)(\+|\-)(\d+.\d+)\s+(\s*)(\+|\-)(\d+.\d+)/ ) {

            chomp $line;

            my $phi_space = $1;
            my $phi_sign = $2;
            my $phi_value = "$2$3";

            my $psi_space = $4;
            my $psi_sign = $5;
            my $psi_value = "$5$6";

             $line = sprintf "%8.4f %8.4f\n", ( ( ( $phi_value + 180 ) / 0.6 ) + 25, ( ( $psi_value - 180 ) / -0.6 ) + 25, );

             print CONVERTED_ANGLES $line;
         }
     }

    close IN;
    unlink ( "phi_psi_temp_angles" ,);

	my $mw = MainWindow -> new( -title => "Results Plot", );

    $mw -> configure( -menu => my $menubar = $mw -> Menu );
    my $file = $menubar -> cascade( -label => '~File' );

	my $size = 650;

	my $canvas = $mw->Canvas( -cursor=>"crosshair", -background=>"black",
				  -width=>$size, -height=>$size )->pack;

    $mw -> protocol( 'WM_DELETE_WINDOW' => sub { $canvas -> destroy; $mw -> destroy; });

    $file -> command(
        -label       => 'Save As Postscript',
        -accelerator => 'Ctrl-s',
        -underline   => 0,
        -command     => sub {

            $canvas -> update;
            $canvas -> postscript( -file => "ramaplot.eps", -colormode => 'color', );
        }
    );
    $file->separator;
    $file->command(
        -label       => "Close",
        -accelerator => 'Ctrl-q',
        -underline   => 0,
        -command     => sub { $mw -> destroy; },
    );

    $mw -> bind( $mw, "<Control-s>" => sub {

            $canvas -> update;
            $canvas -> postscript( -file => "ramaplot.eps", -colormode => 'color', );
        }
    );

    $mw -> bind( $mw, "<Control-q>" => sub { $mw -> destroy; }
    );

    $canvas -> createRectangle( 0, 0, 650, 650, -fill => 'black', );

	$canvas -> createPolygon( 25, 253.5, 90.33, 298.17, 181.67, 298.17, 201.17, 249, 201.17, 204.17, 251.17, 155, 251.17, 56.5, 246.83, 25.17, 25, 25, -fill => '#252525', );
	$canvas -> createPolygon( 64.17, 172.83, 207.67, 172.83, 233.83, 137, 233.83, 36.33, 96.75, 36.33, 96.83, 65.33, 64.17, 99, 64.17, 172.83, -fill => '#404040', );
	$canvas -> createPolygon( 25, 383.17, 51.17, 396.5, 103.33, 396.5, 142.5, 378.67, 146.83, 360.67, 251.17, 360.67, 251.17, 443.5, 25, 443.5, -fill => '#252525', );
	$canvas -> createPolygon( 64.17, 425.67, 233.63, 425.67, 233.83, 392, 157.67, 392, 118.5, 410, 64.17, 410, 64.17, 425.67, -fill => '#404040', );
	$canvas -> createPolygon( 25, 598, 199, 598, 246.83, 625, 25, 625, -fill => '#252525', );
	$canvas -> createPolygon( 429.33, 300.5, 429.33, 163.83, 401, 193, 401, 280.33, 429.33, 300.5, -fill => '#252525', );

	$canvas -> createText( 15, 325, -fill => 'white', -text => 'psi', ); # y axis
	$canvas -> createText( 15, 10, -fill => 'white', -text => '+180', ); # y axis
	$canvas -> createText( 15, 615, -fill => 'white', -text => '-180', ); # y axis
	$canvas -> createText( 325, 630, -fill => 'white', -text => 'phi', ); # x axis
	$canvas -> createText( 35, 630, -fill => 'white', -text => '-180', ); # x axis
	$canvas -> createText( 630, 630, -fill => 'white', -text => '+180', ); # x axis

	$canvas -> createLine( 25, 325, 625, 325, -fill => 'white', ); # y axis
	$canvas -> createLine( 325, 25, 325, 625, -fill => 'white', ); # x axis

    seek CONVERTED_ANGLES, 0, 0;

    while ( <CONVERTED_ANGLES> ) {

        my $phi_angle = substr $_, 0, 8;
        my $psi_angle = substr $_, 9, 8;

        #~ $phi_angle = int ( $phi_angle + 0.5 );
        #~ $psi_angle = int ( $psi_angle + 0.5 );

        #~ my $i = $canvas -> Photo( -width => 600, -height => 600, );
        #~ $canvas -> createImage( 300, 300, -image => $i, );

        #~ $i -> put( '#f3922e', -to => $phi_angle, $psi_angle, $phi_angle + 1, $psi_angle + 1 );

        $canvas -> createText( $phi_angle, $psi_angle, -fill => '#f3922e', -text => '.', );
    }

	close CONVERTED_ANGLES;
    unlink ( "converted_angles", );
}

###################################################################################################
###   Create the plot of the input matrix                                                       ###
###################################################################################################

sub plot {

    my $input = shift;
    my $graph;
    my ( @frames,    @Q,    @Qs,    @q,
         @values,    @data, @step,  @legends,
         @Schlitter, @Andricioaei, );

    our $image_top;

    my $mw = MainWindow -> new( -title => "Results Plot", );
    $mw -> configure( -menu => my $menubar = $mw -> Menu );
    my $file = $menubar -> cascade( -label => '~File' );

    $file -> command(
        -label       => 'Save As Postscript',
        -accelerator => 'Ctrl-s',
        -underline   => 0,
        -command     => sub {

            $graph -> update;
            $graph -> postscript( -file => "$input.eps", -colormode => 'color', );
        }
    );
    $file->separator;
    $file->command(
        -label       => "Close",
        -accelerator => 'Ctrl-q',
        -underline   => 0,
        -command     => sub { $mw -> destroy; },
    );

    $mw -> bind( $mw, "<Control-s>" => sub {

            $graph -> update;
            $graph -> postscript( -file => "$input.eps", -colormode => 'color', );
        }
    );

    $mw -> bind( $mw, "<Control-q>" => sub { $mw -> destroy; }
    );

    my $screenwidth = $mw -> screenwidth;
    my $interval;

    $interval = ( ( $screenwidth <= $header ) ? int ( $header / $screenwidth + 0.5 ) : 1 );

    for ( 1 .. $screenwidth ) {

        push ( @step, $interval * $_ );
    }

    open IN, '<', $input || die "Cannot open $input for reading: $!";

    if ( -z $input ) {

        close IN;
        $image_top -> messageBox( -message => 'The file you are trying to plot seems to be empty. The file is located in ' . getcwd,
                                  -icon => 'warning', );
        $image_top -> destroy;
    }
    else {

        my $i = 0;
        while ( <IN> ) {

            if ( defined $step[$i] && $input =~ /qfract/i && /\s+($step[$i])\s+(\S+)\s+(\S+)\s+(\S+)/ ) {

                $frames[$i] = $1;
                $Q[$i] = $2;
                $Qs[$i] = $3;
                $q[$i] = $4;
                $i++;
            }
            elsif ( defined $step[$i] && $input =~ /entropy/i && /\s+(\S+?)\s+(\S+)\s*(\S*)/ ) {

                $frames[$i] = $1;
                $Andricioaei[$i] = $2;
                $Schlitter[$i] = $3 if ( $3 );
                $i++;
            }
            elsif ( defined $step[$i] && $input =~ /rms|rgyr|bend|tors|dist|surf/i && /\s+($step[$i])\s+([+-]?\d+\.?\d*)/ ) {

                $frames[$i] = $1;
                $values[$i] = $2;
                $i++;
            }
            elsif ( $input =~ /variance/ && /^\s+(\d+)\s+(\d+\.?\d*)\s+(\d+\.?\d*)$/ ) {

                $frames[$i] = $1;
                $values[$i] = $2;
                $i++;
            }
        }

        close IN;

        if ( $linux || $mac ) {

            my ( $dataset1, $dataset2, $dataset3, $dataset4, $dataset5, $dataset6, );

            if ( $input =~ /variance/ ) {

                open VARIANCE, '<', "carma.variance_explained.dat" or die "Cannot open carma.variance_explained.dat for reading : $!\n";

                my $i = 0;
                while ( <VARIANCE> ) {

                    $i++;
                }
                close VARIANCE;

                if ( $i < 2 ) {

                    $mw -> messageBox( -message => 'Only one line read from the file carma.variance_explained.dat. Will not plot', );
                    $mw -> destroy;
                    return;
                }

                $graph = $mw -> PlotDataset( -width => $mw -> screenwidth,
                                             -height => $mw -> screenheight,
                                             -background => 'snow',
                                             -xlabel => 'Frame',
                                             -autoScaleX => 'Off',
                                             -scale => [ '1', $i, '1', '', '', '', '', '', '', ],
                                             -ylabel => 'Value',
                                             -plotTitle => [ $input, 20, ] )
                                             -> pack( qw/ -fill both -expand 1/ );
            }
            else {

                $graph = $mw -> PlotDataset( -width => $mw -> screenwidth,
                                             -height => $mw -> screenheight,
                                             -background => 'snow',
                                             -xlabel => 'Frame',
                                             -ylabel => 'Value',
                                             -plotTitle => [ $input, 20, ] )
                                             -> pack( qw/ -fill both -expand 1/ );
            }

            if ( $input =~ /qfract/i ) {

                $dataset1 = LineGraphDataset -> new( -name => 'Q',
                                                     -xData => \@frames,
                                                     -yData => \@Q,
                                                     -color => 'blue', );
                $dataset2 = LineGraphDataset -> new( -name => 'Qs',
                                                     -xData => \@frames,
                                                     -yData => \@Qs,
                                                     -color => 'green', );
                $dataset3 = LineGraphDataset -> new( -name => 'q',
                                                     -xData => \@frames,
                                                     -yData => \@q,
                                                     -color => 'purple', );

                $graph -> addDatasets( $dataset1, $dataset2, $dataset3, );
            }
            elsif ( $input =~ /entropy/i && @Andricioaei && @Schlitter ) {

                $dataset4 = LineGraphDataset -> new( -name => 'Andricioaei',
                                                     -xData => \@frames,
                                                     -yData => \@Andricioaei,
                                                     -color => 'blue', );
                $dataset5 = LineGraphDataset -> new( -name => 'Schlitter',
                                                     -xData => \@frames,
                                                     -yData => \@Schlitter,
                                                     -color => 'green', );

                $graph -> addDatasets( $dataset4, $dataset5, );
            }
            elsif ( $input =~ /entropy/i ) {

                $dataset4 = LineGraphDataset -> new( -name => 'Andricioaei',
                                                     -xData => \@frames,
                                                     -yData => \@Andricioaei,
                                                     -color => 'blue', );

                $graph -> addDatasets( $dataset4, );
            }
            else {

                $dataset6 = LineGraphDataset -> new( -name => $input,
                                                     -xData => \@frames,
                                                     -yData => \@values,
                                                     -color => 'blue', );

                $graph -> addDatasets( $dataset6, );
            }

            $graph -> plot;

            $graph -> CanvasBind("<$_>", sub {

                $graph -> yviewMoveto( 0 )
            } ) for ( 4, 5, );
        }
        else {

            my $tick = 0;
            if ( $header < 1000 ) {

                $tick = 1;
            }
            elsif ( $header >= 1000 && $header < 10000 ) {

                $tick = 9;
            }
            elsif ( $header >= 10000 && $header < 100000 ) {

                $tick = 99;
            }
            elsif ( $header >= 100000 && $header < 1000000 ) {

                $tick = 999;
            }
            elsif ( $header >= 1000000 && $header < 10000000 ) {

                $tick = 9999;
            }
            else {

                $tick = 99999;
            }

            my $chart = $mw -> Lines( -background => 'snow',
                                      -xlabel => 'Frame',
                                      -ylabel => 'Value',
                                      -title => $input,
                                      -xlabelskip => $tick,
                                      -interval => 1,
                                      -linewidth => 1, )
                                      -> pack( -fill => 'both', -expand => 1, );

            if ( $input =~ /qfract/i ) {

                @data = ( [ @frames ], [ @Q ], [ @Qs ], [ @q ], );
                @legends = ( 'Q', 'Qs', 'q', );
            }
            elsif ( $input =~ /entropy/i && @Andricioaei && @Schlitter ) {

                @data = ( [ @frames ], [ @Andricioaei ], [ @Schlitter ], );
                @legends = ( 'Andricioaei', 'Schlitter', );
            }
            elsif ( $input =~ /entropy/i ) {

                @data = ( [ @frames ], [ @Andricioaei ], );
                @legends = ( 'Andricioaei', );
            }
            else {

                @data = ( [ @frames ], [ @values ], );
                @legends = ( 'Values', );
            }


            $chart -> set_legend(
                -title       => 'Legend',
                -data        => \@legends,
                -titlecolors => 'blue',
            );

            $chart -> set_balloon();
            $chart -> plot( \@data );
        }
    }
}

###################################################################################################
###   Create the help window                                                                    ###
###################################################################################################

sub about {

    my $top = $mw -> Toplevel( -title => "Help", );
    $top -> geometry( "$toplevel_position" );

    $top -> Label( -text => "This is grcarma v$VERSION", ) -> pack;
    $top -> Button( -text => "View online documentation",
                    -command => sub {

        if ( $linux ) {

            system ( "x-www-browser https://github.com/pkoukos/grcarma" );
        }
        elsif ( $mac ) {

            system ( "open https://github.com/pkoukos/grcarma" );
        }
        elsif ( $windows ) {

            system ( "start https://github.com/pkoukos/grcarma" );
        }
    }, ) -> pack;
}

###################################################################################################
###   Create the help window                                                                    ###
###################################################################################################

sub folder_size {

    my $input = shift;
    $input .= '/carma_results*';

    if ( $linux || $mac ) {

        $wd_size = `du -hsc $input 2> /dev/null | grep total 2> /dev/null`;
        chomp $wd_size;
        if ( $wd_size =~ /(\d+,?\d*)(.?)/ ) {

            $wd_prefix = $2 . 'B';
            $wd_size = $1;
            $wd_size =~ s/\,/\./;
        }
    }
    # TODO #
    # else {

        # my $dir = `dir $input /s /-c | find "File(s)"`;

        # if ( $dir !~ /\d* File...\s*(\d*)/ ) {

            # $wd_size = int ( ( $1 / 1000000 ) + 0.5 ) . "MB";
        # }
    # }
}

sub OnResize {

    my ( $mw, $oldSize, $selection, $nofres, $frames, ) = @_;

our $canvas;
    my $newSize = $mw->width . "x" . $mw->height;

    my $height = $mw-> height;
    my $width = $mw-> width;

	my $color = '';

	my $y_step = $height / $nofres;
	my $x_step = $width / $frames;

    $canvas -> configure( -height => $height, -width => $width, );

	open FILE, '<', $selection or die "Cannot open $selection for reading : $!\n";

	my ( $x, $y, ) = ( 0, 0, );
	while ( <FILE> ) {

		if ( $_ eq 'H' ) {

			$color = '#FF0080';
		}
		elsif ( $_ eq 'G' ) {

			$color = '#A00080';
		}
		elsif ( $_ eq 'I' ) {

			$color = '#600080';
		}
		elsif ( $_ eq 'E' ) {

			$color = '#FFC800';
		}
		elsif ( $_ eq 'B' or $_ eq 'T' ) {

			$color = '#6080FF';
		}
		elsif ( $_ eq 'C' ) {

			$color = '#FFFFFF';
		}

		$canvas -> createRectangle( ( $x * $x_step ), ( $height - ( $y_step * ( $y + 1 ) ) ), ( ( $x + 1 ) * $x_step ), ( $height - ( $y_step * $y ) ), -fill => "$color", -outline => undef, ) unless ( $color eq '#FFFFFF' );

		$y++;
		if ( $y == $nofres+1 ) {print 'test';

			$y = 0;
			$x++;
		}
	}

	close FILE;

	$canvas -> update;

    #~ return ( $newSize );
    #~ if ( $$oldSize ne $newSize ) {
#~
        #~ printf( "Resize happened - old size: %s, new size: %s\n", $$oldSize, $newSize );
        #~ $$oldSize = $newSize;
    #~ }
}
