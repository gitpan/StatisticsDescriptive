package Statistics::Descriptive; 
#
# Copyright (c) 1994,1995 Jason Kastner <jason@wagner.com>. All rights 
# reserved. This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.
#

require 5.000;

sub full {
   bless {"data" => [],
          "count" => 0,
          "mean" => 0,
          "pseudo-variance" => 0,
         };
}

sub new {
    $_[0]->full;
}

sub sparse {
   bless {"count" => 0,
          "mean" => 0,
          "pseudo-variance" => 0,
         };
}

sub AddData {
  my ($index,$oldmean) = (1,0);
  while ( defined($val = $_[$index++])) {
     push @{$_[0]->{"data"}}, $val if defined $_[0]->{"data"};
     $oldmean = $_[0]->{"mean"};
     $_[0]->{"count"}++;
     $_[0]->{"mean"} += ($val - $oldmean) / $_[0]->{"count"};
     $_[0]->{"pseudo-variance"} += ($val - $oldmean) * ($val - $_[0]->{"mean"});
  }
  if(defined $_[0]->{"data"}) {
     for (keys %{$_[0]}) {
         next if $_ eq "data"; 
         next if $_ eq "count"; 
         next if $_ eq "mean"; 
         next if $_ eq "pseudo-variance"; 
         delete $_[0]->{$_};
     }
  }
}

sub Count {
  $_[0]->{"count"};
}

sub Mean {
  $_[0]->{"mean"};
}

sub Sum {
  $_[0]->{"mean"}*$_[0]->{"count"};
}

sub Variance {
  if ($_[0]->{"count"}-1 > 0) {
     $_[0]->{"pseudo-variance"} / ($_[0]->{"count"} -1);
  }
  else {
     undef;
  }
}

sub StandardDeviation {
  if ($_[0]->{"count"}-1 > 0) {
     sqrt($_[0]->{"pseudo-variance"}/ ($_[0]->{"count"} -1));
  }
  else {
     undef;
  }
}

sub GetData {
  return undef if !defined $_[0]->{"data"};
  @{$_[0]->{"data"}};
}

sub Max {
  return $_[0]->{"max"} if defined $_[0]->{"max"};
  return undef if !defined $_[0]->{"data"};
  my $max = ${$_[0]->{"data"}}[0];
  for (@{$_[0]->{"data"}}) {
     $max = $_ if $_ > $max;
  }
  $_[0]->{"max"} = $max;
}

sub Min {
  return undef if !defined $_[0]->{"data"};
  return $_[0]->{"min"} if defined $_[0]->{"min"};
  my $min = ${$_[0]->{"data"}}[0];
  for (@{$_[0]->{"data"}}) {
     $min = $_ if $_ < $min;
  }
  $_[0]->{"min"} = $min;
}

sub SampleRange {
      return undef if !defined $_[0]->{"data"};
      $_[0]->Max  - $_[0]->Min;
}
    
sub Median {
    return undef if !defined $_[0]->{"data"};
    return $_[0]->{"median"} if defined $_[0]->{"median"};
    my $count = $_[0]->{"count"};
    @{$_[0]->{"data"}} = sort {$a <=> $b} @{$_[0]->{"data"}};  
    if($count%2 == 1) {
        $_[0]->{"median"} = $_[0]->{"data"}[($count-1)/2];
    }
    else {
        $_[0]->{"median"} = ($_[0]->{"data"}[($count-2)/2] +
                             $_[0]->{"data"}[($count)/2]) / 2;
    }
}

sub TrimmedMean {
  return undef if !defined $_[0]->{"data"};
  my($lower,$upper,$val,$oldmean) = ($_[1],$_[2]);
  $upper = $lower if !defined $upper;
  return $_[0]->{"tm$lower$upper"} if defined $_[0]->{"tm$lower$upper"};
  my $lower_trim = int ($_[0]->{"count"}*$lower); 
  my $upper_trim = int ($_[0]->{"count"}*$upper); 
  my ($tm_count,$tm_mean,$index) = (0,0,$lower_trim);
  @{$_[0]->{"data"}} = sort {$a <=> $b} @{$_[0]->{"data"}};  
  while ($index <= $_[0]->{"count"} - $upper_trim -1) {
     $val = $_[0]->{"data"}[$index++];
     $oldmean = $tm_mean;
     $tm_count++;
     $tm_mean += ($val - $oldmean) / $tm_count;
  }
  $_[0]->{"tm$lower$upper"} = $tm_mean;
}


sub HarmonicMean {
    return undef if !defined $_[0]->{"data"};
    return $_[0]->{"harmonic_mean"} if defined $_[0]->{"harmonic_mean"};
    my $hs = 0;
    for (@{$_[0]->{"data"}}) {
       return $_[0]->{"harmonic_mean"} = 0 if $_ == 0;
       $hs += 1/$_;
    }
    $_[0]->{"harmonic_mean"} = $_[0]->{"count"}/$hs;
}

sub Mode {
    return undef if !defined $_[0]->{"data"};
    return $_[0]->{"mode"} if defined $_[0]->{"mode"};
    my ($md,$occurances,$flag) = (0,0,1);
    my %count;
    for (@{$_[0]->{"data"}}) {
        $count{$_}++;
        $flag = 0 if ($count{$_} > 1);
    }
    if ($flag) {
        return undef;
    }
    for (keys %count) {
       if ($count{$_} > $occurances) {
          $occurances = $count{$_};
          $md = $_;
       }
    }
    $_[0]->{"mode"} = $md;
}

sub GeometricMean {
    return undef if !defined $_[0]->{"data"};
    return $_[0]->{"geometric_mean"} if defined $_[0]->{"geometric_mean"};
    my $gm = 1;
    my $exponent = 1/$_[0]->{"count"};
    for (@{$_[0]->{"data"}}) {
       return undef if $_ < 0;
       $gm *= $_**$exponent;
    }
    $_[0]->{"geometric_mean"} = $gm;
}

sub FrequencyDistribution {
  return undef if !defined $_[0]->{"data"} or $_[0]->{"count"} < 2;
  return %{$_[0]->{"frequency"}} if defined $_[0]->{"frequency"};
  my %bins;
  my $partitions   = $_[1];
  my $interval = $_[0]->SampleRange/$partitions;
  my $iter = $_[0]->{"min"};
  while (($iter += $interval) <  $_[0]->{"max"}) {
      $bins{$iter} = 0;
  }
  $bins{$_[0]->{"max"}} = 0;
  my @k = sort { $a <=> $b } keys %bins;
  ELEMENT:
  foreach $element (@{$_[0]->{"data"}}) {
     for (@k) {
        if ($element <= $_) {
            $bins{$_}++;
            next ELEMENT;
        }
     }
  }
  %{$_[0]->{"frequency"}} = %bins;
}

sub LeastSquaresFit {
  return undef if !defined $_[0]->{"data"} or $_[0]->{"count"} < 2;
  my @x;
  if (!defined $_[1]) {
     @x = 1..$_[0]->{"count"};
  }
  else {
     @x = @_;
     shift @x;
     if ( $_[0]->{"count"} != @x) {
       warn "LeastSquaresFit error: Range and domain are of unequal length.\n";
       return undef;
     }
  }
  my @coefficients;
  my ($sigmaxy, $sigmax, $sigmaxx) = (0,0,0);
  my $sigmay = $_[0]->Sum;
  my $count = $_[0]->{"count"};
  my $iter = 0;
  for (@x) {
      $sigmaxy += $_ * $_[0]->{"data"}[$iter];
      $sigmax += $_;
      $sigmaxx += $_*$_;
      $iter++;
  }
  $coefficients[1] = ($count*$sigmaxy - $sigmax*$sigmay)/
		     ($count*$sigmaxx - $sigmax*$sigmax);
  $coefficients[0] = ($sigmay - $coefficients[1]*$sigmax)/$count;
  @coefficients;
}

1;
