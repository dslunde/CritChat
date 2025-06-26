import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:critchat/features/polls/domain/entities/poll_entity.dart';
import 'package:critchat/features/polls/domain/usecases/create_poll_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/vote_on_poll_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/get_fellowship_polls_usecase.dart';
import 'package:critchat/features/polls/domain/usecases/add_custom_option_usecase.dart';
import 'package:critchat/features/polls/domain/repositories/poll_repository.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_event.dart';
import 'package:critchat/features/polls/presentation/bloc/poll_state.dart';

class PollBloc extends Bloc<PollEvent, PollState> {
  final CreatePollUseCase createPollUseCase;
  final VoteOnPollUseCase voteOnPollUseCase;
  final GetFellowshipPollsUseCase getFellowshipPollsUseCase;
  final AddCustomOptionUseCase addCustomOptionUseCase;
  final PollRepository pollRepository;

  StreamSubscription<List<PollEntity>>? _pollsSubscription;
  StreamController<List<PollEntity>>? _pollsController;
  List<PollEntity> _lastPolls = [];

  PollBloc({
    required this.createPollUseCase,
    required this.voteOnPollUseCase,
    required this.getFellowshipPollsUseCase,
    required this.addCustomOptionUseCase,
    required this.pollRepository,
  }) : super(PollInitial()) {
    on<GetFellowshipPolls>(_onGetFellowshipPolls);
    on<CreatePoll>(_onCreatePoll);
    on<VoteOnPoll>(_onVoteOnPoll);
    on<AddCustomOption>(_onAddCustomOption);
    on<ClosePoll>(_onClosePoll);
    on<DeletePoll>(_onDeletePoll);
    on<RemoveVote>(_onRemoveVote);
    on<PollsUpdated>(_onPollsUpdated);
  }

  @override
  Future<void> close() {
    _pollsSubscription?.cancel();
    _pollsController?.close();
    return super.close();
  }

  Future<void> _onGetFellowshipPolls(
    GetFellowshipPolls event,
    Emitter<PollState> emit,
  ) async {
    try {
      emit(PollLoading());

      // Clean up existing subscription and controller
      await _pollsSubscription?.cancel();
      _pollsController?.close();

      // Create a new broadcast controller that caches the last value
      _pollsController = StreamController<List<PollEntity>>.broadcast(
        onListen: () {
          // When a new listener subscribes, immediately send the last known polls
          if (_lastPolls.isNotEmpty && !_pollsController!.isClosed) {
            _pollsController!.add(_lastPolls);
          }
        },
      );

      // Listen to the Firebase stream and forward data to our controller
      _pollsSubscription = getFellowshipPollsUseCase(event.fellowshipId).listen(
        (polls) {
          _lastPolls = polls; // Cache the polls
          if (!_pollsController!.isClosed) {
            _pollsController!.add(polls);
          }
          add(PollsUpdated(polls: polls));
        },
        onError: (error) {
          if (!_pollsController!.isClosed) {
            _pollsController!.addError(error);
          }
          add(PollsUpdated(polls: []));
        },
      );
    } catch (e) {
      emit(PollError(message: 'Failed to load polls: ${e.toString()}'));
    }
  }

  Future<void> _onPollsUpdated(
    PollsUpdated event,
    Emitter<PollState> emit,
  ) async {
    try {
      final polls = event.polls.cast<PollEntity>();
      emit(PollsLoaded(polls: polls));
    } catch (e) {
      emit(PollError(message: 'Failed to update polls: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePoll(CreatePoll event, Emitter<PollState> emit) async {
    try {
      // Don't emit loading - let the stream update handle the new poll
      final poll = await createPollUseCase(
        title: event.title,
        description: event.description,
        fellowshipId: event.fellowshipId,
        expiresAt: event.expiresAt,
        allowCustomOptions: event.allowCustomOptions,
        allowMultipleChoice: event.allowMultipleChoice,
        initialOptions: event.initialOptions,
      );

      emit(PollCreated(poll: poll));
    } catch (e) {
      emit(PollError(message: 'Failed to create poll: ${e.toString()}'));
    }
  }

  Future<void> _onVoteOnPoll(VoteOnPoll event, Emitter<PollState> emit) async {
    try {
      // Don't emit loading - let the stream update handle the vote changes
      await voteOnPollUseCase(
        pollId: event.pollId,
        optionIds: event.optionIds,
        fellowshipId: event.fellowshipId,
      );

      emit(PollVoteSuccess(pollId: event.pollId, optionIds: event.optionIds));
    } catch (e) {
      emit(
        PollError(
          message: 'Failed to vote: ${e.toString()}',
          pollId: event.pollId,
        ),
      );
    }
  }

  Future<void> _onAddCustomOption(
    AddCustomOption event,
    Emitter<PollState> emit,
  ) async {
    try {
      final option = await addCustomOptionUseCase(
        pollId: event.pollId,
        optionText: event.optionText,
      );

      emit(PollOptionAdded(pollId: event.pollId, option: option));
    } catch (e) {
      emit(
        PollError(
          message: 'Failed to add option: ${e.toString()}',
          pollId: event.pollId,
        ),
      );
    }
  }

  Future<void> _onClosePoll(ClosePoll event, Emitter<PollState> emit) async {
    try {
      await pollRepository.closePoll(event.pollId);
      emit(PollClosed(pollId: event.pollId));
    } catch (e) {
      emit(
        PollError(
          message: 'Failed to close poll: ${e.toString()}',
          pollId: event.pollId,
        ),
      );
    }
  }

  Future<void> _onDeletePoll(DeletePoll event, Emitter<PollState> emit) async {
    try {
      await pollRepository.deletePoll(event.pollId);
      emit(PollDeleted(pollId: event.pollId));
    } catch (e) {
      emit(
        PollError(
          message: 'Failed to delete poll: ${e.toString()}',
          pollId: event.pollId,
        ),
      );
    }
  }

  Future<void> _onRemoveVote(RemoveVote event, Emitter<PollState> emit) async {
    try {
      await pollRepository.removeVote(
        pollId: event.pollId,
        optionId: event.optionId,
      );

      emit(PollVoteRemoved(pollId: event.pollId, optionId: event.optionId));
    } catch (e) {
      emit(
        PollError(
          message: 'Failed to remove vote: ${e.toString()}',
          pollId: event.pollId,
        ),
      );
    }
  }
}
