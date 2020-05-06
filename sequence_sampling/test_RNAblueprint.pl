#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: test_RNAblueprint.pl
#
#        USAGE: ./test_RNAblueprint.pl  
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 31.07.2017 11:45:19
#     REVISION: ---
#===============================================================================

use v5.12;
use warnings;
use autodie ':all';

use Benchmark qw( cmpthese );
use RNAblueprint;
# use Math::Random::MT qw(srand rand irand);    # a bit slower than default



##############################################################################
##                                   Subs                                   ##
##############################################################################

# Generate a random seq of AUGCs of a given length.
# Arguments:
#   length: length of sequence to be generated
# Returns a random sequence of A, U, G and C of the requested length.
sub random_seq ($) {
    my $length = shift;
    # die "Invalid length $length" unless $length =~ /^\d+$/;

    state $symbols      = [qw( A U G C )];
    state $symbol_count = @$symbols;

    # return join q{}, map { $symbols->[int rand $symbol_count] } 1..$length;
    return join q{}, @{$symbols}[  map {int rand $symbol_count} 1..$length  ];
}

# Build a sequence generator that, given either an initial sequence of a
# positive sequence lengths, randomly mutates one position of the sequence and
# returns the next sequence with each successive call. The returned generator
# is also capable of reverting the last mutation step when called with
# argument -1. If a length is passed to the factory, the initial sequence is a
# random sequence.
# Arguments: either but NOT both of...
#   sequence: use this as initial sequence and to determine target sequence
#       length
#   length: generate sequences of this length. Start with a random sequence.
# Returns iterator that returns the next random sequence when called without
# arguments, and which reverts the last mutation step if called with argument
# -1. In this case, 1 is returned if reverting was successful, and a false
# value otherwise (i.e. no mutation done yet, or already reverted one step).
sub seq_gen_factory ($) {
    my $arg = shift;
    my ($seq_length, $current_seq);

    $arg = uc($arg =~ s/T/U/igr);       # ensure upper-case and substitute Ts

    # Check argument sanity
    if ($arg =~/^\d+$/) {
        $seq_length = $arg;
        $current_seq = random_seq $seq_length;
    }
    elsif ($arg =~ /^[AUGC]+$/) {
        $current_seq = $arg;
        $seq_length = length $arg;
    }
    else {
        die "Invalid argument '$arg'";
    }

    my ($last_pos, $last_symbol);           # for reverting the last change

    return sub {
        if (@_ and $_[0] == -1) {                   # revert last change
            # Nothing generated yet or already reverted one step
            return unless defined $last_symbol;

            substr $current_seq, $last_pos, 1, $last_symbol;    # undo
            $last_symbol = undef;
            return 1;
        }

        my $next_pos = int rand $seq_length;        # gen next random position

        # Assign a new DISTINCT random sequence of length 1 to a random
        # position, i.e.  change exactly one nucleotide, and keep the replaced
        # one for revert to the last state later if requested.
        my $next_symbol;
        do {
            $next_symbol = random_seq 1;
            $last_symbol = substr $current_seq, $next_pos, 1, $next_symbol;
        } while $next_symbol eq $last_symbol;

        $last_pos = $next_pos;

        return $current_seq;
    }
}


# Class implementing a gradient descent optimization. The score function is
# minimized.
# #### Class members ####
# new: Constructor.
#   Arguments:
#       generator: a closure / code ref that keeps track of its current state
#           and that randomly generates and returns the next state when called
#           without arguments. When called with argument -1, the generator
#           needs to revert the last single mutation step performed and
#           restore the state it had before (to correct unfavorable moves).
#       score_func: code ref that, when called on the current state, returns
#           its score / energy / fitness, where a LOWER score is BETTER, i.e.,
#           a minimization is performed
#       decision_func: code ref of function that, when called with the current
#           state's score and the potential next state's score, decides
#           whether to accept or reject this step. By default, a function
#           accepting a step iff the next state's energy is lower than the
#           current one's is used, resulting in a classical gradient descent
#           behavior. By making the descision function non-deterministic, a
#           Metropolis--Hastings-like behavior can be established. If the
#           decision function as an internal state, it could be used to
#           implement e.g. simulated annealing, i.e.  reduce the probability
#           of accepting a worse state over time. The descision function needs
#           to return its choice as 1 or false.
#   Optional arguments:
#       init_state: initial state of the simulation. By default, the generator
#           is employed to generate the initial state. Make sure generator
#           uses the same initial state!
#       default_max_successive_fails: specifies default value for the
#           max_successive_fails parameter of run() [100]
#   Returns GradientDescent object.
#
# step: Perform single optimization step, i.e. generate the next state which
#       is then accepted or rejected.
#   Returns 1 if the generated state has been accepted as next state, and
#       otherwise false.
#
# run: Continue performing optimization steps until the maximal number of
#      successive rejections has been reached.
#   Optional arguments:
#       max_successive_fails: abort after that many successive failed steps.
#           defaults to the value specified during construction.
#   Returns the final state and its energy. The results can also be accessed
#   using the current_state() and current_state_score() getters
#
# init_state:            Returns the initial state of the optimization.
# init_state_score:      Returns the score of the initial state.
# current_state:         Returns the initial state of the optimization.
# current_state_score:   Returns the score of the current state.
# step_count:            Returns number of steps already done.
# successful_step_count: Returns number of successful / non-rejected steps.
package GradientDescent {

    use List::Util qw( all );


    sub new {
        my $class = shift;
        my $self  = bless {@_}, $class;

        # Check for required args
        my @required_args = qw( score_func generator );
        die 'Missing args, require all of ' . join( ', ', @required_args)
            unless all {defined $self->{$_}} @required_args;

        # Let run() stop after n unsuccessful iterations by default
        $self->{default_max_successive_fails} = 100
            unless defined $self->{default_max_successive_fails};

        # By default, perform simple gradient descent
        $self->{decision_func} ||= sub { my ($old, $new) = @_; $new < $old };

        # Generate initial state unless one has been specified
        $self->{init_state} = $self->{generator}()
            unless defined $self->{init_state};
        $self->{init_state_score} = $self->{score_func}($self->init_state);

        # TODO actually, for nested state structures, we need a deep copy
        $self->{current_state}       = $self->{init_state};
        $self->{current_state_score} = $self->{init_state_score};

        return $self;
    }


    # Perform single MINIMIZATION step
    sub step {
        my $self             = shift;
        my $next_state       = $self->{generator}();
        my $next_state_score = $self->{score_func}($next_state);

        $self->{step_count}++;

        # On success, update current score
        if ($self->{decision_func}(
                                    $self->current_state_score,
                                    $next_state_score,
                                  )
           ) {
            $self->{current_state}       = $next_state;
            $self->{current_state_score} = $next_state_score;
            $self->{successful_step_count}++;

            return 1;       # sucess
        }
        else {
            $self->{generator}(-1);     # revert last step
            return;         # fail
        }
    }


    # Continue performing optimization steps until the maximal number of
    # successive rejections has been reached.
    # Optional arguments:
    #   max_successive_fails: Allow up to that many failed steps until giving
    #       up.
    sub run {
        my $self = shift;
        my $max_successive_fails = @_
                                   ? shift
                                   : $self->{default_max_successive_fails};

        my $successive_fail_count = 0;
        while ($successive_fail_count <= $max_successive_fails) {
            if ($self->step()) {
                $successive_fail_count = 0;
            }
            else {
                $successive_fail_count++;
            }
        }

        return ($self->current_state, $self->current_state_score);
    }


    # Public getters
    sub init_state            { $_[0]->{init_state}                 }
    sub init_state_score      { $_[0]->{init_state_score}           }
    sub current_state         { $_[0]->{current_state}              }
    sub current_state_score   { $_[0]->{current_state_score}        }
    sub step_count            { $_[0]->{step_count} || 0            }
    sub successful_step_count { $_[0]->{successful_step_count} || 0 }

    1;
}


# Love the name. Generates a Metropolis--Hastings style decision function with
# a given scale factor. This function can be passed an old state's score and a
# new state's score, and it will either accept (returns 1) or reject (returns
# false) the transition to this new state. If the new state has a lower score,
# the transition is always accepted. Otherwise, it is accepted with a
# probability that is proportional to the fraction of the probability of the
# old and new states (as calculated from their Boltzmann weight).
# Optional arguments:
#   scale_factor: Value from interval (0,inf). Lower values punish tranisitons
#       to worse states more severely; at high scale factors, transitions are
#       always accepted [1]
sub metropolis_hastings_decision_function_factory {
    my $scale_factor = @_ ? shift : 1;

    return sub {
        my ($old_score, $new_score) = @_;
        return 1 if $new_score < $old_score;    # always accept better states

        # TODO this always accepts equally good states. We don't want that, do
        # we?!

        # If new state is worse, accept with a probability proportional to
        # Boltzmann weight of the score / energy difference
        return exp( ($old_score-$new_score) / $scale_factor ) > rand 1;
    }
}


##############################################################################
##                                   Main                                   ##
##############################################################################

say 'Testing RNAblueprint...';

my $seq_length = 15;
my $seq_count  = 10;
my $dep_graph  = new RNAblueprint::DependencyGraphMT(['.' x $seq_length]);

say "Dependency graph has " . $dep_graph->number_of_connected_components()
    . " connected components";
say "Found ", $dep_graph->number_of_sequences, " solutions in total";
say $dep_graph->get_sequence;

my %known_seq;
foreach (1..$seq_count) {
    $dep_graph->sample_clocal();        # re-sample one random component
    # $dep_graph->sample();               # re-sample entire sequence
    printf "%2d: ", $_;

    my $seq = $dep_graph->get_sequence;
    $known_seq{$seq}++;

    if ($known_seq{$seq} > 1) {
        say $known_seq{$seq} . ". encounter";
    }
    else {
        say $seq;
    }
}

say "\nUsing my own sloppy generator without any structural constraints";

my $random_seq_gen = seq_gen_factory $seq_length;
%known_seq = ();

foreach (1..$seq_count) {
    printf "%2d: ", $_;

    my $seq = $random_seq_gen->();
    $known_seq{$seq}++;

    if ($known_seq{$seq} > 1) {
        say $known_seq{$seq} . ". encounter";
    }
    else {
        say $seq;
    }
}

say 'Benching the hard way!!1';

    $seq_length =  20;
     $seq_count = 1e3;
my $bench_count = 100;              # run 15 sec: 3e3;

say "Running $bench_count benchmark iterations...";
cmpthese( $bench_count, {
    RNAblueprint => sub {
        my $dep_graph  = new RNAblueprint::DependencyGraphMT(['.' x $seq_length]);
        foreach (1..$seq_count) {
            $dep_graph->sample_clocal();
            my $seq = $dep_graph->get_sequence();
        }
    },
    my_hack      => sub {
        my $random_seq_gen = seq_gen_factory $seq_length;
        foreach (1..$seq_count) {
            my $seq = $random_seq_gen->();
        }
    },
});


say "\nTesting gradient walk optimization class.";

my $score_gc_content = sub {
    my $seq = shift;
    return -1 * grep {$_ eq 'G' or $_ eq 'C'} split //, $seq;
};

my $start_seq = 'A' x 15;
my $grad_walk = GradientDescent->new(
    generator                    => seq_gen_factory $start_seq,
    score_func                   => $score_gc_content,
    init_state                   => $start_seq,
    default_max_successive_fails => 10,
    decision_func => metropolis_hastings_decision_function_factory( 1/2 ),
);

say 'Gradwalking now..., start sequence: ', $grad_walk->init_state,
    '  score: ', $grad_walk->init_state_score;
foreach (1..8) {
    my $success = $grad_walk->step ? "success" : "no success";
    say 'Gradwalking single step, result:    ', $grad_walk->current_state,
    '  score: ', $grad_walk->current_state_score, "  $success";
}
say 'Continuing...';
$grad_walk->run( );
say 'Gradwalking finished, result:       ', $grad_walk->current_state,
    '  score: ', $grad_walk->current_state_score;
say 'performed ', $grad_walk->step_count, ' steps in total, ',
    $grad_walk->successful_step_count, ' of which were successful';


exit 0;

