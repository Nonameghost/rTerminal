#!/usr/bin/perl
# Rev: 11 
# Thanks: artem 
# Author: Nonameghost 
# Date: 2012-07-20 12:22:47 -0700 (Friday, 20 June 2012) 


#TODO:
#*Allow for multiple page viewing.
#*Add configuration options and files.
#*Add Verbose mode, which allows full length titles, text, and other information.

#*IF POSSIBLE: Add authentication, then attempt commenting and text posts.


#use strict;
use Term::ANSIScreen;
use WWW::Mechanize;
use JSON -support_by_pp;
use Data::Dump;
use Term::ReadKey;

($wchar, $hchar, $wpixels, $hpixels) = GetTerminalSize();

my $os = $^O;

my $titleLength = 90;
my $textLength = 500;

my $mainLoop = 1;
my $checkLoop = 1;

my $subRed = "";
my $query = "";

my %pcache = ();

sub reddit
{
	print ("||======================================||\n");
	print ("||") . ("  ###   ") . ("####  ") . ("##    ") . ("##    ") . ("###  ", "cyan") . ("#####  ") . ("||\n");  
	print ("||") . ("  #  #  ") . ("#     ") . ("# #   ") . ("# #   ") . (" #   ", "cyan") . ("  #    ") . ("||\n"); 
	print ("||") . ("  ###   ") . ("####  ") . ("#  #  ") . ("#  #  ") . (" #   ", "cyan") . ("  #    ") . ("||\n");
	print ("||") . ("  # #   ") . ("#     ") . ("# #   ") . ("# #   ") . (" #   ", "cyan") . ("  #    ") . ("||\n");
	print ("||") . ("  #  #  ") . ("####  ") . ("##    ") . ("##    ") . ("###  ", "cyan") . ("  #    ") . ("||\n");
	print ("||======================================||\n");
}

sub shorten
{
	my $string = $_[0];
	my $max = $_[1];
	
	my $length = length($string);
	
	$diff = $length - $max;
	
	foreach my $i (1..$diff)
	{
		$string = substr($string, 0, -1);
	}
	return $string;
}

sub paragraph
{
	my $string = $_[0];
	my $tabs = $_[1];
	my $color = $_[2];
	my $headLength = $_[3];
	$string =~ s/\n/ /g;
	
	my @array = split(//, $string);
	my $max = $wchar - ($tabs*8);
	my $length = @array;

	my $a=0;
	my $c=0;
	my $i=0;
	for $i(0..$length)
	{	
		if ($c == 0)
		{
			for $z(1..$tabs)
			{
				print "\t";
			}
		}
		
		if ($a <= $headLength)
		{
			print ("$array[$i]");
			$a++;
			$c++;
		}
		else
		{
			print ("$array[$i]");
			$a++;
			$c++;
		}
		
		if ($c >= $max)
		{
			print "\n";
			$c = 0;
		}
	}
	print "\n\n";
}
sub clear
{
	if ($os eq "MSWin32")
	{system("CLS");}

	else
	{system("clear");}
}

sub refresh
{
	if ($subRed eq '')
	{
		fetchSubreddit("http://www.reddit.com/.json");
	}
	else
	{
		fetchSubreddit("http://www.reddit.com/r/$subRed.json");
	}
}

sub fetchSubreddit
{
	$timeRefresh = localtime(time);
	
	clear();
  	my ($json_url) = @_;
  	my $browser = WWW::Mechanize->new();
  	eval
  	{
		# download the json page:
		print "\nFetching content from: $json_url\n";
		$browser->get( $json_url );
		my $content = $browser->content();
		my $json = new JSON;
		 
		my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
	 
	    	# iterate
		my $postNum = 1;
		my %phsh = ();
		reddit();
		
		if ($subRed eq '')
		{
			print ("\nCurrent Subreddit: Front Page!");
		}
		else
		{
			print ("\nCurrent Subreddit: /r/$subRed");
		}
		print ("\nLast Refresh: $timeRefresh\n");
		print ("==========================================\n");
		foreach my $children(@{$json_text->{"data"}->{"children"}})
		{
			my $data = $children->{"data"};
			
			$phsh{author} = $data->{"author"};
			$phsh{title} = $data->{"title"};    
			my $tLen = length($phsh{title});
			if ($tLen>$titleLength)
			{
				$phsh{title} = shorten($phsh{title}, $titleLength) . "...";
			}
		
			$phsh{subreddit} = $data->{subreddit};
			$phsh{url} = $data->{url};
		
			$phsh{permalink} = "http://www.reddit.com" . $data->{permalink};
			$phsh{permalink} = substr($phsh{permalink}, 0, -1);
		
			$pcache{$postNum} = $phsh{permalink};
		
			$phsh{score} = $data->{"score"};
			$phsh{ups} = $data->{"ups"};
			$phsh{downs} = $data->{"downs"};
			$phsh{numComments} = $data->{"num_comments"};
			
			$phsh{created} = $data->{"created"};
			$created = scalar localtime($phsh{created});
			
			$phsh{isSelf} = $data->{is_self};
			$phsh{selfText} = $data->{selftext};
			if (length($phsh{selfText})>$textLength)
			{
				$phsh{selfText} = shorten($phsh{selfText}, $textLength) . "...";
			}
		
			$phsh{edited} = $data->{edited};
			$phsh{over18} = $data->{over_18};
		
			print ("=====\n\n");
			print ("$postNum: ($phsh{score}) " . $phsh{title} . "\n\n");
	
			print ("      " . "(") . ($phsh{ups}) . ("|") . ($phsh{downs}) . (")");
			print ("      " . "/r/" . $phsh{subreddit});
			print ("      " . $phsh{numComments} . " comments");
			print ("      " . $created);
			if ($phsh{edited} eq false)
			{
				print "";
			}
			else
			{
				print ("*", "bold red");
			}
	
			if ($phsh{over18} eq true)
			{
				print ("      NSFW", "bold red");
			}
			else
			{
				print "";#Pass
			}
	
			print "\n\n";
	
			print ("By: ") . ($phsh{author}) . "\n";
			print ("Link: ") . ($phsh{url}) . "\n";
			print ("Comments: ") . ($phsh{permalink}) . "\n"; 

		
			if ($phsh{isSelf} eq true)
			{
		
				print ("Text: ") . ($phsh{selfText}) . "\n\n";

			}
			else
			{
				print "\n";
			}
		
			$postNum++;
	    	}
		print ("======\n");
  };
  # catch crashes:
  if($@)
  {
    print "[[JSON ERROR]] JSON parser crashed! $@\n";
  }
}

sub fetchComments
{
	clear();
  	my ($json_url) = @_;
  	my $browser = WWW::Mechanize->new();
  	eval
  	{
	    # download the json page:
	    print "\nFetching content from: $json_url\n";
	    $browser->get( $json_url );
	    my $content = $browser->content();
	    my $json = new JSON;
	 
	    # these are some nice json options to relax restrictions a bit:
	    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
	    
		my $count = 0;
		my $hiddenPosts = 0;
		my %postHash = ();
		my %comHash = ();
		
		clear();
		reddit();
		
	     	my $children = $json_text->[1]{data}{children};
	      
	      
		print ("==========================================\n");

		
		for my $child (@$children) 
		{
		  	my $author = $child->{data}{author};
		  	my $auLength = length($author);
		  	my $body = $child->{data}{body};
		  	my $all = $author . ":" . $body;
		  	paragraph($all,0,"red",$auLength);
			print "\n";
		  	
		  	foreach my $reply(@{$child->{data}->{replies}->{data}->{children}})
		  	{
		  		my $data = $reply->{data};
		  		my $author = $data->{author};
		  		my $auLength = length($author);
		  		my $body = $data->{body};
		  		my $all = $author . ":" . $body;
		  		paragraph($all,1,"blue",$auLength);
				print "\n";
		  		
		  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
			  	{
			  		my $data = $reply->{data};
			  		my $author = $data->{author};
			  		my $auLength = length($author);
			  		my $body = $data->{body};
			  		my $all = $author . ":" . $body;
			  		paragraph($all,2,"green",$auLength);
					print "\n";
			  		
			  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
				  	{
				  		my $data = $reply->{data};
				  		my $author = $data->{author};
				  		my $auLength = length($author);
				  		my $body = $data->{body};
				  		my $all = $author . ":" . $body;
				  		paragraph($all,3,"yellow",$auLength);
						print "\n";
				  		
				  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
					  	{
					  		my $data = $reply->{data};
					  		my $author = $data->{author};
					  		my $auLength = length($author);
					  		my $body = $data->{body};
					  		my $all = $author . ":" . $body;
					  		paragraph($all,4,"cyan",$auLength);
							print "\n";
					  		
					  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
						  	{
						  		my $data = $reply->{data};
						  		my $author = $data->{author};
						  		my $auLength = length($author);
						  		my $body = $data->{body};
						  		my $all = $author . ":" . $body;
						  		paragraph($all,5,"magenta",$auLength);
								print "\n";
						  		
						  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
							  	{
							  		my $data = $reply->{data};
							  		my $author = $data->{author};
							  		my $auLength = length($author);
							  		my $body = $data->{body};
							  		my $all = $author . ":" . $body;
							  		paragraph($all,6,"bold black",$auLength);
									print "\n";
							  		
							  		foreach my $reply(@{$reply->{data}->{replies}->{data}->{children}})
							  		{
							  			$hiddenPosts++;
							  		}
							  		my $strHiddenPosts = "$hiddenPosts posts hidden.\n";
							  		paragraph($strHiddenPosts,7,"bold white",0) unless ($hiddenPosts == 0);
							  		$hiddenPosts = 0;
							  	}
						  	}
					  	}
					  	
				  	}	
			  	}
			  		
		  	}	
		  	
		  	
		}
	};
	if($@)
	{
    	print "[[JSON ERROR]] JSON parser crashed! $@\n";
  	}
}

sub fetchSearch
{
	my $timeRefresh = localtime(time);
	
	clear();
  	my ($json_url) = @_;
  	my $browser = WWW::Mechanize->new();
  	eval
  	{
		# download the json page:
		print "\nFetching content from: $json_url\n";
		print "This may take a while...\n";
		$browser->get( $json_url );
		my $content = $browser->content();
		my $json = new JSON;
		 
		my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
	 
	    	# iterate
		my $postNum = 1;
		my %phsh = ();
		reddit();
		
		print ("\nLast Refresh: $timeRefresh\n", "bold white\n");
		print ("Query: $query\n");
		print ("==========================================\n");
		foreach my $children(@{$json_text->{"data"}->{"children"}})
		{
			my $data = $children->{"data"};
			
			$phsh{author} = $data->{"author"};
			$phsh{title} = $data->{"title"};    
			my $tLen = length($phsh{title});
			if ($tLen>$titleLength)
			{
				$phsh{title} = shorten($phsh{title}, $titleLength) . "...";
			}
		
			$phsh{subreddit} = $data->{subreddit};
			$phsh{url} = $data->{url};
		
			$phsh{permalink} = "http://www.reddit.com" . $data->{permalink};
			$phsh{permalink} = substr($phsh{permalink}, 0, -1);
		
			$pcache{$postNum} = $phsh{permalink};
		
			$phsh{score} = $data->{"score"};
		     	$phsh{ups} = $data->{"ups"};
		     	$phsh{downs} = $data->{"downs"};
		     	$phsh{numComments} = $data->{"num_comments"};
		     	
		     	$phsh{created} = $data->{"created"};
		     	$created = scalar localtime($phsh{created});
		     	
		     	$phsh{isSelf} = $data->{is_self};
			$phsh{selfText} = $data->{selftext};
			if (length($phsh{selfText})>$textLength)
			{
				$phsh{selfText} = shorten($phsh{selfText}, $textLength) . "...";
			}
		
			$phsh{edited} = $data->{edited};
			$phsh{over18} = $data->{over_18};
		
			print ("=====\n\n");
			print ("$postNum: ($phsh{score}) " . $phsh{title} . "\n\n");
	
			print ("      " . "(") . ($phsh{ups}) . ("|") . ($phsh{downs}) . (")");
			print ("      " . "/r/" . $phsh{subreddit});
			print ("      " . $phsh{numComments} . " comments");
			print ("      " . $created);
			if ($phsh{edited} eq false)
			{
				print "";
			}
			else
			{
				print ("*", "bold red");
			}
	
			if ($phsh{over18} eq true)
			{
				print ("      NSFW", "bold red");
			}
			else
			{
				print "";#Pass
			}
	
			print "\n\n";
	
			print ("By: ") . ($phsh{author}) . "\n";
			print ("Link: ") . ($phsh{url}) . "\n";
			print ("Comments: ") . ($phsh{permalink}) . "\n"; 

		
			if ($phsh{isSelf} eq true)
			{
		
				print ("Text: ") . ($phsh{selfText}) . "\n\n";

			}
			else
			{
				print "\n";
			}
		
			$postNum++;
	    	}
		print ("======\n");
  };
  # catch crashes:
  if($@)
  {
    print "[[JSON ERROR]] JSON parser crashed! $@\n";
  }
}
	
	
	
	
###INIT###
clear();
reddit();
print ("\nWelcome to /r/Terminal, bringing Reddit to your terminal of choice!\n");
print ("Thanks to Artem Russakovski for a tutorial on using the perl JSON module.\nAnd to anyone else who helped me hack this together!\n");
print ("Version: 0.10 Alpha\n");
print ("==========================================\n");
print ("Press ENTER to continue...");
$raw = <>;
clear();
reddit();
print ("What subbreddit would you like to view?\n");
print ("(Leave blank for front page)\n/r/");
$subRed = <>;
chomp($subRed);

if ($subRed eq '')
{
	fetchSubreddit("http://www.reddit.com/.json");
}
else
{
	fetchSubreddit("http://www.reddit.com/r/$subRed.json");
}
while ($mainLoop == 1)
{
	print ("Enter a command: ");
	$input = <>;
	chomp($input);
	
	if ($input eq "refresh")
	{
		refresh();
	}
	elsif ($input eq "exit")
	{
		clear();
		$mainLoop = 0;
		exit;
	}
	elsif ($input eq "new")
	{
		print ("Enter a subreddit or type '*' to go back:\n/r/");
		$checkSub = <>;
		chomp($checkSub);

		if ($checkSub eq '')
		{
			$subRed = $checkSub;
			fetchSubreddit("http://www.reddit.com/.json");
		}
		elsif ($checkSub eq "*")
		{
			refresh();
		}
		else
		{
			$subRed = $checkSub;
			fetchSubreddit("http://www.reddit.com/r/$subRed.json");
		}	
	}
	elsif ($input eq "comments")
	{
		print "Which post would you like to view? - ";
		my $id = <>;
		chomp($id);
		
		fetchComments($pcache{$id} . ".json");
	}
	elsif ($input eq "search")
	{
		print "Query? - ";
		$query = <>;
		chomp($query);
		if ($query eq '')
		{
			refresh();
		}
		else
		{
			fetchSearch("http://www.reddit.com/search.json?q=$query");
		}
	}
}
