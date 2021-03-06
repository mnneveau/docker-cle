#!/usr/bin/perl

use strict;
use warnings;

use feature qw(say);

die("wrong number of arguments") unless scalar(@ARGV) == 2;
my ($docm_out_vcf, $outdir) = @ARGV;

open(my $docm_vcf_fh, $docm_out_vcf)
    or die("couldn't open $docm_out_vcf to read");
open(my $docm_filter_fh, ">", "$outdir/docm_filter_out.vcf")
    or die("couldn't open docm_filter_out.vcf for write");

while (<$docm_vcf_fh>) {
    chomp;
    if (/^##/) {
        say $docm_filter_fh $_;
    }
    elsif (/^#CHROM/) {
        my @columns = split /\t/, $_;
        $columns[9]  = 'NORMAL';
        $columns[10] = 'TUMOR';
        my $header = join "\t", @columns;
        say $docm_filter_fh $header;
    }
    else {
        my @columns = split /\t/, $_;
        my @tumor_info = split /:/, $columns[10];
        my ($AD, $DP) = ($tumor_info[1], $tumor_info[2]);
        next unless $AD;
        my @AD = split /,/, $AD;
        shift @AD; #the first one is ref count
        for my $ad (@AD) {
            if ($ad > 5 and $ad/$DP > 0.01) {
                say $docm_filter_fh $_;
                last;
            }
        }
    }
}

close($docm_vcf_fh);
close($docm_filter_fh);
