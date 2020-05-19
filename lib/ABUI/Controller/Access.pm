package ABUI::Controller::Access;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper::Compact 'ddc';
use lib $ENV{HOME} . '/sandbox/Data-Science-FromScratch/lib';
use Data::MachineLearning::Elements;
use File::Slurper 'read_text';
use Encoding::FixLatin 'fix_latin';
use HTTP::Simple;
use JSON::MaybeXS;
use Set::Tiny;
use Statistics::Lite 'mean';

sub size {
  my $self = shift;

  my $artists = $self->rs('Artist')->count;
  my $recordings = $self->rs('Recording')->count;

  $self->render(json => { artists => $artists, recordings => $recordings });
}

sub main {
  my $self = shift;

  my $artist1 = $self->param('artist1');
  my $artist2 = $self->param('artist2');
  my $artist3 = $self->param('artist3');
  my $track = $self->param('track');
  my $genre = $self->param('genre');
  my $average = $self->param('average');
  my $all = $self->param('all');
  my $file = $self->param('file');

  my $genres;
  my $artists;
  my $tracks;
  my $averages;
  my $diffs;
  my $recordings;
  my $members;

  my $correct = 0;
  my $union = 0;
  my $intersection = 0;

  my $all_artists = $self->rs('Artist');
  my $all_recordings = $self->rs('Recording');

  if ($file) {
    my $content = read_text($file);
    my $raw = decode_json($content);
    return $self->render(text => ddc($raw->{metadata}));
  }
  elsif ($artist1 && !$genre && !$average && !$all && !$artist2 && !$artist3) {
    if ($track) {
      my $artist = $all_artists->search({ 'LOWER(name)' => lc($artist1) })->first;
      my $recs = $artist->recordings;

      while (my $recording = $recs->next) {
        my $file = $self->config('base') . $recording->file;
        my $content = read_text($file);
        my $raw = decode_json($content);

        if ($raw->{metadata}{tags}{file_name} =~ /$track/i) {
          push @$tracks, {
            name => scalar fix_latin($raw->{metadata}{tags}{file_name}),
            file => $file,
            mbid => $raw->{metadata}{tags}{musicbrainz_recordingid}[0],
          };
        }
      }
    }
    else {
      $artists = $all_artists->search(
        { 'LOWER(name)' => { like => '%' . lc($artist1) . '%' } },
        { order_by => 'name' }
      );
    }
  }
  elsif ($artist1 && $all) {
    my $artist = $all_artists->search({ 'LOWER(name)' => lc($artist1) })->first;
    my $recs = $artist->recordings;

    while (my $recording = $recs->next) {
      my $file = $self->config('base') . $recording->file;
      my $content = read_text($file);
      my $raw = decode_json($content);

      push @$recordings, {
        name => scalar fix_latin($raw->{metadata}{tags}{file_name}),
        file => $file,
        mbid => $raw->{metadata}{tags}{musicbrainz_recordingid}[0],
      };
    }
  }
  elsif ($artist1 && $genre && !$artist2) {
    my $artist = $all_artists->search({ 'LOWER(name)' => lc($artist1) })->first;

    die 'No such artist' unless $artist;
    die 'Artist has no MBID' unless $artist->mbid;

    my $url = 'https://musicbrainz.org/ws/2/artist/' . $artist->mbid . '?inc=genres&fmt=json';

    my $content = get $url;

    my $raw = decode_json($content);

    $genres = [ map { $_->{name} }
      sort { $b->{count} <=> $a->{count} || $a cmp $b }
        @{ $raw->{genres} } ];
  }
  elsif ($artist1 && $genre && $artist2) {
    my $art1 = $all_artists->search({ name => $artist1 })->first;
    my $art2 = $all_artists->search({ name => $artist2 })->first;

    die 'No such artist' unless $art1 && $art2;
    die 'Artist has no MBID' unless $art1->mbid && $art2->mbid;

    my %genres;

    for my $artist ($art1, $art2) {
      my $url = 'https://musicbrainz.org/ws/2/artist/' . $artist->mbid . '?inc=genres&fmt=json';

      my $content = get $url;

      my $raw = decode_json($content);

      $genres{ $artist->name } = [ map { $_->{name} } sort { $b->{count} <=> $a->{count} || $a cmp $b } @{ $raw->{genres} } ];
    }

    my $s1 = Set::Tiny->new(@{ $genres{$artist1} });
    my $s2 = Set::Tiny->new(@{ $genres{$artist2} });

    $intersection = scalar $s1->intersection($s2)->members;
    $union = scalar $s1->union($s2)->members;

    $members->{$artist1} = $genres{$artist1};
    $members->{$artist2} = $genres{$artist2};
    $members->{ $artist1 . ' only' } = [ $s1->difference($s2)->members ];
    $members->{ $artist2 . ' only' } = [ $s2->difference($s1)->members ];
    $members->{Shared} = [ $s1->intersection($s2)->members ];
  }
  elsif ($artist1 && $average) {
    $averages = $self->_compute_averages($artist1);
  }
  elsif ($artist1 && $artist2 && $artist3) {
    my $averages1 = $self->_compute_averages($artist1);
    my $averages2 = $self->_compute_averages($artist2);
    my $averages3 = $self->_compute_averages($artist3);

    my %features1;
    my %features2;
    my %features3;

    my $ml = Data::MachineLearning::Elements->new;

    my @features = qw(
      barkbands_crest
      barkbands_flatness_db
      barkbands_kurtosis
      barkbands_skewness
      barkbands_spread
      beats_loudness
      bpm_histogram_first_peak_bpm
      bpm_histogram_first_peak_spread
      bpm_histogram_first_peak_weight
      bpm_histogram_second_peak_bpm
      bpm_histogram_second_peak_spread
      bpm_histogram_second_peak_weight
      chords
      dissonance
      erbbands_crest
      erbbands_flatness_db
      erbbands_kurtosis
      erbbands_skewness
      erbbands_spread
      hfc
      hpcp_entropy
      key
      melbands_crest
      melbands_flatness_db
      melbands_kurtosis
      melbands_skewness
      melbands_spread
      pitch_salience
      silence_rate_20dB
      silence_rate_30dB
      silence_rate_60dB
      spectral_centroid
      spectral_complexity
      spectral_decrease
      spectral_energy
      spectral_energyband_high
      spectral_energyband_low
      spectral_energyband_middle_high
      spectral_energyband_middle_low
      spectral_entropy
      spectral_flux
      spectral_kurtosis
      spectral_rms
      spectral_rolloff
      spectral_skewness
      spectral_spread
      spectral_strongpeak
      tuning
      zerocrossingrate
      average_loudness
      beats_count
      bpm
      danceability
      dynamic_complexity
      length
      onset_rate
    );

    for my $feature (@features) {
      my $vector1 = [map { abs $averages1->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages1];
      my $vector2 = [map { abs $averages2->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages2];
      $features1{$feature} = $ml->distance($vector1, $vector2);
    }

    for my $feature (@features) {
      my $vector1 = [map { abs $averages1->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages1];
      my $vector2 = [map { abs $averages3->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages3];
      $features2{$feature} = $ml->distance($vector1, $vector2);
    }

    for my $feature (@features) {
      my $vector1 = [map { abs $averages2->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages2];
      my $vector2 = [map { abs $averages3->{$_} } grep { $_ eq $feature || $_ =~ /^$feature\_/ } sort keys %$averages3];
      $features3{$feature} = $ml->distance($vector1, $vector2);
    }

    for my $feature (@features) {
      my $bool = $features2{$feature} > $features1{$feature}
              && $features3{$feature} > $features1{$feature} ? 1 : 0;
      $diffs->{$feature} = $bool;
      $correct++ if $bool;
    }
  }

  $self->render(
    artist1          => $artist1,
    artist2          => $artist2,
    artist3          => $artist3,
    artists          => $artists,
    genre            => $genre,
    genres           => $genres,
    track            => $track,
    tracks           => $tracks,
    average          => $average,
    averages         => $averages,
    diffs            => $diffs,
    correct          => $correct,
    all              => $all,
    recordings       => $recordings,
    members          => $members,
    union            => $union,
    intersection     => $intersection,
    total_artists    => $all_artists->count,
    total_recordings => $all_recordings->count,
  );
}

sub _compute_averages {
  my ($self, $who) = @_;

  my $artist = $self->rs('Artist')->search({ 'LOWER(name)' => lc($who) })->first;
  my $recs = $artist->recordings;

  my %keys = (
    'C' => 0, 'C#' => 1, 'Db' => 1,
    'D' => 2, 'D#' => 3, 'Eb' => 3,
    'E' => 4,
    'F' => 5, 'F#' => 6, 'Gb' => 6,
    'G' => 7, 'G#' => 8, 'Ab' => 8,
    'A' => 9, 'A#' => 10, 'Bb' => 10,
    'B' => 11,
  );

  my %avg;

  while (my $recording = $recs->next) {
    my $content = read_text($self->config('base') . $recording->file);
    my $raw = decode_json($content);

    my $track_name = $raw->{metadata}{tags}{file_name};
    next unless $track_name =~ /\.mp3$/; # Only consider MP3 files

    push @{ $avg{length} }, $raw->{metadata}{audio_properties}{length};

    for my $section (keys %$raw) {
      next unless $section eq 'rhythm' || $section eq 'tonal' || $section eq 'lowlevel';

      for my $feature (keys %{ $raw->{$section} }) {
        if (!ref $raw->{$section}{$feature}) {
          if ($feature eq 'key_key' || $feature eq 'chords_key') {
            push @{ $avg{$feature} }, $keys{ $raw->{$section}{$feature} };
          }
          elsif ($feature eq 'key_scale' || $feature eq 'chords_scale') {
            push @{ $avg{$feature} }, $raw->{$section}{$feature} eq 'major' ? 1 : 0;
          }
          else {
            push @{ $avg{$feature} }, $raw->{$section}{$feature};
          }
        }
        if (ref($raw->{$section}{$feature}) eq 'HASH') {
          for my $measure (keys %{ $raw->{$section}{$feature} }) {
            if (!ref $raw->{$section}{$feature}{$measure}) {
              push @{ $avg{ $feature . '_' . $measure } }, $raw->{$section}{$feature}{$measure};
            }
          }
        }
      }
    }
  }

  %avg = map { $_ => mean(@{ $avg{$_} }) } keys %avg;

  return \%avg;
}

1;
