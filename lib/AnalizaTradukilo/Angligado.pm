#!/usr/bin/env perl

# Analiza Tradukilo: Tradukas de Esperanto al la angla.
# Copyright © 2012 Patrick M. Niedzielski.
#
# Ĉi tiu subrutinaro estas libera softvaro: vin oni permesas redonadi
# ĝin kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
# License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
# de la permisilo, aŭ (se vi volas) iu posta versio.
#
# Ĉi tiun subrutinaron donadis oni pro tiu espero, ke ĝi estu utila,
# sed SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ
# TAŬGECO POR CERTA CELO.  Vidu la GNU Affero General Public License
# trovi plie da detaloj.
#
# Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
# tiu subrutinaro.  Se ne, vidu <http://www.gnu.org/licenses/>.

package AnalizaTradukilo::Angligado;

use Modern::Perl;
use encoding "utf-8";
use utf8;
use feature 'unicode_strings';
use locale ':not_characters';
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use base 'Exporter';
our @EXPORT = qw( angligi );

use Lingua::EN::Inflect qw( PL A );
use Lingua::EN::Conjugate qw( conjugate );

=head1 NAME

AnalizaTradukilo::Angligado - Subrutinaro por traduki analizitajn
Esperantajn frazojn.

=head1 VERSION

La versio 1.0ª

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

Uzu ĉi tiun subrutinaron tiele:

    use AnalizaTradukilo::Angligado;
    use AnalizaTradukilo::Radikanalizo;
    use AnalizaTradukilo::Frazanalizo;
    my @vortanalizoj = ();
    foreach my $vorto (qw( la katon mi amas )) {
        push @vortanalizoj, analizi_radikojn($vorto);
    }
    my $analizo = analizi_frazon(\@vortanalizoj);
    say angligi($analizo);

=head1 DESCRIPTION

Ĉi tiu subrutinaro enhavas subrutinojn, kiuj tradukas en anglan la
analizon de AnalizaTradukilo::Frazanalizo;

=head2 Subroutines

=over 4

=item B<angligi($analizo)>

Redonas kordeton de la angla traduko de la donita C<$analizo>.

=cut

use Data::Dumper;

our %vortaro = (
    'esti' => 'be',
    'sekvi' => 'follow',
    'ami' => 'love',
    'kato' => 'cat',
    'bona' => 'good',
    'feliĉa' => 'happy',
    'mi' => 'I',
    'ni' => 'we',
    'vi' => 'you',
    'neĝo' => 'snow',
    'blanka' => 'white',
    'hundo' => 'dog'
);

sub angligi {
    my $analizo = shift
        || die "Neniu analizo donita al „angligi“";

    my $nps = trovi_ĉiujn($analizo, 'N');
    my $vp = trovi_unuan($analizo, 'V');
    my $pps = trovi_ĉiujn($analizo, 'P');

    my $subjektoj = [];
    my $objekto;
    foreach my $np (@$nps) {
        my $ĉu = ĉu_np_akuzativas($np);
        push $subjektoj, $np unless $ĉu;
        $objekto = $np if $ĉu;
    }

    my $svorto = redoni_substantivon($subjektoj->[0]);

    my $vvorto = redoni_verbon($vp);
    my $tempo;
    $tempo = 'present' if ($vvorto->{'finaĵo'} eq 'as');
    $tempo = 'past'    if ($vvorto->{'finaĵo'} eq 'is');
    $tempo = 'modal'   if ($vvorto->{'finaĵo'} eq 'os');
    $tempo = 'modal'   if ($vvorto->{'finaĵo'} eq 'us');
    $tempo = 'modal'   if ($vvorto->{'finaĵo'} eq 'u');
    my $modal;
    $modal = 'will'   if ($vvorto->{'finaĵo'} eq 'os');
    $modal = 'would'  if ($vvorto->{'finaĵo'} eq 'us');
    $modal = 'should' if ($vvorto->{'finaĵo'} eq 'u');

    my ($pronomo, $aktuala_pronomo);
    my $ĉu_subjekto_multecas = 0;
    $ĉu_subjekto_multecas = 1 if $svorto->{'finaĵo'} =~ /j$/;
    $pronomo = 'he'   if !$ĉu_subjekto_multecas;
    $pronomo = 'they' if $ĉu_subjekto_multecas;

    $aktuala_pronomo = $pronomo = 'I'    if ($svorto->{'originala'} eq 'mi');
    $aktuala_pronomo = $pronomo = 'we'   if ($svorto->{'originala'} eq 'ni');
    $aktuala_pronomo = $pronomo = 'you'  if ($svorto->{'originala'} eq 'vi');
    $aktuala_pronomo = $pronomo = 'you'  if ($svorto->{'originala'} eq 'ci');
    $aktuala_pronomo = $pronomo = 'he'   if ($svorto->{'originala'} eq 'li');
    $aktuala_pronomo = $pronomo = 'she'  if ($svorto->{'originala'} eq 'ŝi');
    $aktuala_pronomo = $pronomo = 'it'   if ($svorto->{'originala'} eq 'ĝi');
    $aktuala_pronomo = $pronomo = 'they' if ($svorto->{'originala'} eq 'ili');

    my $radikaro = plej_bona_radikaro($vvorto->{'eblaj_radikaroj'});
    my $vortkordo = $vortaro{$radikaro->{'ebla_radikaro'}[0].'i'};
    
    my $anglavortkordo = conjugate(verb    => $vortkordo,
                                   tense   => $tempo,
                                   pronoun => $pronomo,
                                   modal   => $modal);
    
    unless (defined $aktuala_pronomo) {
        $anglavortkordo =~ s/^\S+\s//;
        $anglavortkordo = np_traduki($subjektoj->[0])
            . $anglavortkordo;
    }

    if (scalar(@$subjektoj) == 2) {
        $anglavortkordo .= ' ' . np_traduki($subjektoj->[1]);
    }

    if (defined $objekto) {
        $anglavortkordo .= ' ' . np_traduki($objekto);
    }
    
    
    return $anglavortkordo;
}

sub np_traduki {
    my $np = shift;

    my $ĉu_a = 0;

    my $traduko = '';
    if ($np->[1][0] eq 'SPEC') {
        $traduko .= 'the ';
    } else {
        $ĉu_a = 1;
    }

    for (@{$np->[-1]}) {
        next unless ref eq 'ARRAY';
        if ($_->[0] eq 'COMP') {
            my $radikaro =
                plej_bona_radikaro($_->[1][1][1][1]{'eblaj_radikaroj'});
            $traduko .= $vortaro{$radikaro->{'ebla_radikaro'}[0].'a'}
            . ' ';
        } elsif ($_->[0] eq 'N') {
            my $radikaro =
                plej_bona_radikaro($_->[1]{'eblaj_radikaroj'});
            # if ($_->[1]{'originala'} =~ /[mncvlŝĝ(?:il)s(?:on)]in?/) {
            #     for ($_->[1]{'originala'}) {
            #         $traduko .= 
            my $vorttraduko =
                $vortaro{$radikaro->{'ebla_radikaro'}[0].'o'};
            if ($_->[1]{'finaĵo'} =~ /jn?$/) {
                $traduko .= PL($vorttraduko);
            } else {
                $traduko .= $vorttraduko;
            }
            
            $traduko .= ' ';
        }
    }
    return A($traduko) if $ĉu_a;
    return $traduko;
}

sub plej_bona_radikaro {
    my $radikaroj = shift;
    
    my $plejbona;
    my $rango = -10000;
    foreach (@$radikaroj) {
        if ($rango < $_->{'rango'}) {
            $rango = $_->{'rango'};
            $plejbona = $_;
        }
    }

    return $plejbona;
}

sub redoni_verbon {
    my $vp = shift;
    
    return $vp->[1][1][1];
}

sub redoni_substantivon {
    my $np = shift;

    return redoni_substantivon_helpilo($np->[-1]);
}

sub redoni_substantivon_helpilo {
    my $n_stango = shift;

    foreach my $ena (@$n_stango) {
        next unless ref $ena eq 'ARRAY';
        return redoni_substantivon_helpilo($ena) if $ena->[0] eq "N'";
    }

    # ni nun havas N', kiu nur havas COMP-ojn kaj eble unu N.
    return ($n_stango->[1][1][1][1][1])
        if $n_stango->[1][0] eq 'COMP';
    return $n_stango->[1][1];
}

sub redoni_spec {
    my $np = shift;

    return $np->[1][1] if $np->[1][0] eq 'COMP';
    return '';
}

sub ĉu_np_akuzativas {
    my $np = shift
        || die "Neniu NP donita al „ĉu_np_akuzativas“";

    return ĉu_np_akuzativas_helpilo($np->[-1]);
}

sub ĉu_np_akuzativas_helpilo {
    my $n_stango = shift;

    foreach my $ena (@$n_stango) {
        next unless ref $ena eq 'ARRAY';
        return ĉu_np_akuzativas_helpilo($ena) if $ena->[0] eq "N'";
    }

    # ni nun havas N', kiu nur havas COMP-ojn kaj eble unu N.
    return ĉu_comp_akuzativas($n_stango->[1])
        if $n_stango->[1][0] eq 'COMP';
    return 1 if $n_stango->[1][1]{'finaĵo'} =~ /n$/;
    return 0;
}

sub ĉu_comp_akuzativas {
    my $comp = shift
        || die "Neniu COMP donita al „ĉu_comp_akuzativas“";

    return 1 if $comp->[1][1][1][1]{'finaĵo'} =~ /n$/;
    return 0;
}

sub trovi_unuan {
    my $analizo = shift
        || die "Neniu analizo donita al „trovi_unuan“";
    my $x = shift
        || die "Neniu X'-tipo donita al „trovi_unuan“";

    my $ĉiuj = trovi_ĉiujn($analizo, $x);
    return $ĉiuj->[0];
}

sub trovi_ĉiujn {
    my $analizo = shift
        || die "Neniu analizo donita al „trovi_ĉiujn“";
    my $x = shift
        || die "Neniu X'-tipo donita al „trovi_ĉiujn“";

    my $trovitaj = [];
    foreach my $xp (@$analizo) {
        push $trovitaj, $xp if ($xp->[0] =~ /^${x}P$/);
    }
    return $trovitaj;
}

=back

=head1 BUGS

Jam sciitaj problemoj:


=head1 AUTHORS

Tiun ĉi subrutinaron skribigis Patrick M. Niedzielski
C<< <PatrickNiedzielski@gmail.com> >>.

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Patrick M. Niedzielski.

Ĉi tiu subrutinaro estas libera softvaro: vin oni permesas redonadi
ĝin kaj/aŭ ŝanĝi ĝin laŭ la kondiĉoj de la GNU Affero General Public
License, kiel eldonis la Free Software Foundation, aŭ la versio 3ª
de la permisilo, aŭ (se vi volas) iu posta versio.

Ĉi tiun subrutinaron donadis oni pro tiu espero, ke ĝi estu utila, sed
SEN IA GARANTIO; sen eĉ la implica garantio de VENDEBLECO aŭ TAŬGECO
POR CERTA CELO.  Vidu la GNU Affero General Public License trovi
plie da detaloj.

Vi jam ricevu kopion de la GNU Affero General Public License kun ĉi
tiu subrutinaro.  Se ne, vidu L<http://www.gnu.org/licenses/>.

=cut

1;
__END__
