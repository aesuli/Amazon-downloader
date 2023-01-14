#!/usr/bin/perl

# Amazon reviews downloader
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

# usage: ./downloadAmazonReviews.pl <domain> <list of IDs of amazon products>
# example: ./downloadAmazonReviews.pl com B0040JHVC2 B004CG4CN4
# output: a directory ./amazonreviews/<domain>/<ID> is created for each product ID; HTML files containing reviews are downloaded and saved in each directory.

use strict;
use LWP::UserAgent;
use HTTP::Request;
use WWW::Mechanize::PhantomJS;
binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

$| = 1; #autoflush

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
$ua->agent('Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.30 (KHTML, like Gecko) Ubuntu/11.04 Chromium/12.0.742.91 Chrome/12.0.742.91 Safari/534.30');

mkdir "amazonreviews";

my $sleepTime = 1;

my $domain = shift;
mkdir "amazonreviews/$domain";

my $id = "";
while($id  = shift) {

    my $dir = "amazonreviews/$domain/$id";
    mkdir $dir;

    my $urlPart1 = "http://www.amazon.".$domain."/product-reviews/";
		my $urlPart2 = "/ref=cm_cr_getr_d_paging_btm_";
		my $urlPart3 = "?ie=UTF8&showViewpoints=1&sortBy=recent&pageNumber=";

    my $referer = $urlPart1.$id.$urlPart2."1".$urlPart3."1";

    my $page = 1;
		my $lastPage = 1;
    while($page<=$lastPage) {

		my $url = $urlPart1.$id.$urlPart2.$page.$urlPart3.$page;

		print $url;

		
		my $mech = WWW::Mechanize::PhantomJS->new(
			launch_arg => ['ghostdriver/src/main.js' ],
		);
		
		$mech->get($url);
				
		my $response = $mech->response(headers => 0);
		if($response->is_success) {
			print " GOTIT\n";
			my $content = $mech->content( format => 'html' );

			while($content =~ m#<span class="a-size-medium a-text-beside-button totalReviewCount">(([1-9]*[0-9],)*[1-9]?[1-9]?[0-9])</span>#gs ) {
				my $temp = $1;	
				$temp =~ s/,//;
				my $val = int ($temp/10) + 1;
				if($val>$lastPage) {
					$lastPage = $val;
				}

				$matched = 1
			}

			# Try again if no usable content was returned
			if(!$matched) {
			    print "Unusable results, trying again\n";
			    next;
			}

			if(open(CONTENTFILE, ">./$dir/$page")) {
				binmode(CONTENTFILE, ":utf8");
				print CONTENTFILE $content;
				close(CONTENTFILE);
				print "ok\t$domain\t$id\t$page\t$lastPage\n";
			}
			else {
				print "failed\t$domain\t$id\t$page\t$lastPage\n";
			}

			if($sleepTime>0) {
				--$sleepTime;
			}
		}
		else {
			if($mech->status()==503) {
				--$page;
				++$sleepTime;
				print " TIMEOUT ".$response->code." retrying (new timeout $sleepTime)\n";
			}
			else {
				print " Downloaded ". ($page-1). " pages for product id $id (end code:".$response->code.")\n";
				last;
			}
		}
		++$page;
		sleep($sleepTime);
    }
}

