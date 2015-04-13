#!/usr/bin/perl

# Amazon reviews extractor
# Copyright (C) 2015  Andrea Esuli
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
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# usage: ./extractAmazonReviews.pl <list of files downloaded with downloadAmazonReviews.pl>|<list of directories containing the files downloaded with downloadAmazonReviews.pl>
# note: when a directory name is specified, only the file residing in that directory are processed, not files eventually contained in subdirectories, i.e., there is no recursive visit of subdirectories.
# example: ./extractAmazonReviews.pl amazonreviews/com/B0040JHVC2
# example: ./extractAmazonReviews.pl amazonreviews/com/B0040JHVC2/1 amazonreviews/com/B0040JHVC2/2  amazonreviews/com/B0040JHVC2/3
# output: a simple CSV to standard output
# note: use redirect to save output to a file
# example: ./extractAmazonReviews.pl amazonreviews/com/B0040JHVC2 > B0040JHVC2.com.csv

use strict;
use  File::Spec;

my $filename ="";
my $count = 0;

while($filename= shift) {
    if(-f $filename) {
	extract($filename);
    }
    elsif(-d $filename) {
	opendir(DIR, $filename) or next;
	while(my $subfilename = readdir(DIR)) {
	    extract(File::Spec->catfile($filename,$subfilename));
	}
	closedir(DIR);
    }
}

sub extract {
    my($filename) = $_[0];
    open (FILE, "<", $filename) or return;
    my $whole_file;
    {
	local $/;
	$whole_file = <FILE>;
    }
    close(FILE);
	
    $whole_file =~ m#product\-reviews/([A-Z0-9]+)/ref\=cm_cr_pr_hist#gs;
    my $model = $1;
    
    $whole_file =~ m#cm_cr-review_list.*?>(.*?)<div class=\"a-form-actions a-spacing-top-extra-large#gs;
    $whole_file = $1;
	
    while ($whole_file =~ m#a-section review\">(.*?)report-abuse-link#gs) {
		my $block = $1;

		$block =~ m#star-(.) review-rating#gs;
		my $rating = $1;
		
		$block =~ m#review-title.*?>(.*?)</a>#gs;
		my $title = $1;

		$block =~ m#review-date">(.*?)</span>#gs;
		my $date = $1;

		$date =~ m/on ([A-Za-z]+) ([0-9]+), ([0-9]+)/;
		my $month = $1;

		if($month eq "January") {
			$month = "01";
		}
		elsif($month eq "February") {
			$month = "02";
		}
		elsif($month eq "March") {
			$month = "03";
		}
		elsif($month eq "April") {
			$month = "04";
		}
		elsif($month eq "May") {
			$month = "05";
		}
		elsif($month eq "June") {
			$month = "06";
		}
		elsif($month eq "July") {
			$month = "07";
		}
		elsif($month eq "August") {
			$month = "08";
		}
		elsif($month eq "September") {
			$month = "09";
		}
		elsif($month eq "October") {
			$month = "10";
		}
		elsif($month eq "November") {
			$month = "11";
		}
		elsif($month eq "December") {
			$month = "12";
		}
		else {
			$month = "XX";
		}

		my $newDate = "XX"; 
		if($month ne "XX") {
			$newDate = sprintf ( "$3$month%02d",$2);
		}

		my $helpfulTotal = 0;
		my $helpfulYes = 0;
		if($block =~ m#review-votes.*?([0-9]+).*?([0-9]+)#) {
		   $helpfulTotal = ($1, $2)[$1 < $2];
		   $helpfulYes =  ($1, $2)[$1 > $2];
		}
		my $userId = "ANONYMOUS";
		if($block =~ m#profile\/(.*?)["/].*?\<\/div\>.*?\<\/div\>.#gs) {
			$userId = $1;
		}


		$block =~ m#base review-text">(.*?)</span#gs;
		my $review = $1;
		$review =~ s/^\s+|\s+$//g;
		$review =~ s/\n/ /g;
		$review =~ s/\r/ /g;
		$review =~ s/"/'/g;

		if(length($review) > 0) {
			print "\"$count\",\"$newDate\",\"$model\",\"$rating\",\"$helpfulYes\",\"$helpfulTotal\",\"$date\",\"$userId\",\"$title\",\"$review\"\n";
		}
		++$count;
    }
}
