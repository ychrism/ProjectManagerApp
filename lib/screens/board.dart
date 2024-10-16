// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../services/websocket.dart';

final Logger logger = Logger();

class BoardScreen extends StatefulWidget {
  final int boardId;
  final Map<String, dynamic>? userProfile;

  const BoardScreen({super.key, required this.boardId, required this.userProfile});

  @override
  BoardScreenState createState() => BoardScreenState();
}

class BoardScreenState extends State<BoardScreen> {
  final Api _api = Api();
  List<Map<String, dynamic>> cards = [];
  Map<String, dynamic> boardDetails = {};
  bool isLoading = true;
  final Map<String, Color> membersColors = {};
  String _sortCriteria = 'none';
  String _filterCriteria = 'none';
  String _filterValue = '';
  bool _sortAscending = true;
  late Timer _updateTimer;
  late WebSocketService _webSocketService; // Declare WebSocketService

  @override
  void initState() {
    super.initState();

    // Set up the Timer immediately
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkAndUpdateCardStatuses();
    });

    _fetchBoardDetailsAndCards();

    // Initialize WebSocketService
    _webSocketService = WebSocketService(channelPath: '/ws/cards_status_update/${widget.boardId}/');
    _initWebSocket();
  }

  // Initialize WebSocket connection
  Future<void> _initWebSocket() async {
    try {
      await _webSocketService.initWebSocket();
      _listenForNewMessages();
    } catch (e) {
      _showSnackBar('Failed to connect to WebSocket. Please try again later.');
    }
  }

  // Listen for new messages from WebSocket
  void _listenForNewMessages() {
    _webSocketService.listenForNewMessages().listen((newMessage) {
      if (newMessage['type'] == 'card_status_update') {
        _handleCardStatusUpdate(newMessage['message']);
      }
    });
  }

  // Method to check start date time of TO-DO tasks and update status to DOING is time is up.
  Future<void> _checkAndUpdateCardStatuses() async {
    final now = DateTime.now();

    for (var card in cards) {
      if (card['status'] == 'TODO') {
        final startDate = DateTime.parse(card['start_date']);
        if (now.isAfter(startDate)) {
          try {
            await _api.updateCardStatus(cardId: card['id'], newStatus: 'DOING');
            logger.i("Card status update request sent");
          } catch (e) {
            logger.e(
                'Failed to update card ${card['id']} status');
          }
        }
      }
    }

  }


  // Method to fetch current board details and its cards
  Future<void> _fetchBoardDetailsAndCards() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedBoardDetails = await _api.fetchBoardDetails(boardId: widget.boardId);
      final fetchedCards = await _api.fetchCards(boardId: widget.boardId);
      setState(() {
        boardDetails = fetchedBoardDetails;
        cards = fetchedCards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to fetch data');
    }
  }

  // Method to show information in popup at bottom
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Update card status local state based on the received update
  void _handleCardStatusUpdate(Map<String, dynamic> update) {
    setState(() {
      final cardIndex = cards.indexWhere((card) => card['id'] == update['card_id']);
      if (cardIndex != -1) {
        cards[cardIndex]['status'] = update['new_status'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 50,
        title: Text(boardDetails.isNotEmpty ? boardDetails['name'] : 'Board', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.sort, color: Colors.white), onPressed:_showSortOptions),
          IconButton(icon: const Icon(Icons.filter_list_alt, color: Colors.white), onPressed:_showFilterOptions,),
        ],
        backgroundColor: Colors.black,
        // back button to go back to boards list. By default automaticallyImplyLeading = true do the job but we had to change color to white
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // If data still loading, print a circular progress indicator else the expected content
          : Container(
        decoration: boardDetails.isNotEmpty
        ? BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(boardDetails['pic']),
              fit: BoxFit.cover, // Adjust the fit as needed
            ),
          )
        : const BoxDecoration(
            color: Colors.white10
          ),
        child: Center( // Your content here
          child: Column(
            children: [
              const SizedBox(height: 13),
              _buildMemberAvatars(),
              _buildProgressBar(),
              Expanded(
                child: _buildBoardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build avatars of board members
  Widget _buildMemberAvatars() {
    return Container(
      height: 45,
      width: 200,
      margin: const EdgeInsets.only(right: 300),
      child: Stack(
        children: [
          Positioned(left: 10, child: _buildAvatar(Colors.blue)),
          Positioned(left: 30, child: _buildAvatar(Colors.green)),
          Positioned(left: 50, child: _buildAvatar(Colors.orange)),
          Positioned(left: 70, child: _buildAvatar(Colors.purple)),
          Positioned(left: 90, child: _buildAvatar(Colors.grey, label: '+5')),
        ],
      ),
    );
  }

  // Method to build single user avatar
  Widget _buildAvatar(Color color, {String? label}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: CircleAvatar(
        backgroundColor: color,
        child: label != null ? Text(label, style: const TextStyle(color: Colors.white)) : null,
      ),
    );
  }


  // Method to show board progress
  Widget _buildProgressBar() {
    double progress = boardDetails['progress'];
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: boardDetails.isNotEmpty ? progress/100 : 0.0,
                backgroundColor: Colors.black,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 16,
                borderRadius: BorderRadius.circular(18),
              ),
              Text(boardDetails.isNotEmpty ? "$progress%" : "0%", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  // Sort options method
  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Priority'),
                onTap: () => _showSortDirectionOptions('priority'),
              ),
              ListTile(
                title: const Text('Due Date'),
                onTap: () => _showSortDirectionOptions('dueDate'),
              ),
              ListTile(
                title: const Text('None'),
                onTap: () {
                  setState(() {
                    _sortCriteria = 'none';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Sort direction options (ascending and descending) method
  void _showSortDirectionOptions(String criteria) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort Direction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ascending'),
                onTap: () {
                  setState(() {
                    _sortCriteria = criteria;
                    _sortAscending = true;
                  });
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.arrow_upward),
              ),
              ListTile(
                title: const Text('Descending'),
                onTap: () {
                  setState(() {
                    _sortCriteria = criteria;
                    _sortAscending = false;
                  });
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.arrow_downward),
              ),
            ],
          ),
        );
      },
    );
  }

  // Filter options method
  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Priority'),
                onTap: _showPriorityFilterOptions,
              ),
              ListTile(
                title: const Text('Status'),
                onTap: _showStatusFilterOptions,
              ),
              ListTile(
                title: const Text('Due Soon'),
                onTap: () {
                  setState(() {
                    _filterCriteria = 'dueSoon';
                    _filterValue = '';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('None'),
                onTap: () {
                  setState(() {
                    _filterCriteria = 'none';
                    _filterValue = '';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriorityFilterOptions() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Priority'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Low'),
                onTap: () => _applyFilter('priority', 'LOW'),
              ),
              ListTile(
                title: const Text('Medium'),
                onTap: () => _applyFilter('priority', 'MEDIUM'),
              ),
              ListTile(
                title: const Text('High'),
                onTap: () => _applyFilter('priority', 'HIGH'),
              ),
              ListTile(
                title: const Text('Critical'),
                onTap: () => _applyFilter('priority', 'CRITICAL'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilterOptions() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('TODO'),
                onTap: () => _applyFilter('status', 'TODO'),
              ),
              ListTile(
                title: const Text('DOING'),
                onTap: () => _applyFilter('status', 'DOING'),
              ),
              ListTile(
                title: const Text('BLOCKED'),
                onTap: () => _applyFilter('status', 'BLOCKED'),
              ),
              ListTile(
                title: const Text('DONE'),
                onTap: () => _applyFilter('status', 'DONE'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilter(String criteria, String value) {
    setState(() {
      _filterCriteria = criteria;
      _filterValue = value;
    });
    Navigator.pop(context);
  }


  // Method to build board categories list (TODO, DOING, BLOCKED, and DONE)
  Widget _buildBoardList() {
    // Apply sorting
    List<Map<String, dynamic>> sortedCards = List.from(cards);
    if (_sortCriteria == 'priority') {
      sortedCards.sort((a, b) => _comparePriority(a['priority'], b['priority']));
    } else if (_sortCriteria == 'dueDate') {
      sortedCards.sort((a, b) => DateTime.parse(a['due_date']).compareTo(DateTime.parse(b['due_date'])));
    }

    if (!_sortAscending) {
      sortedCards = sortedCards.reversed.toList();
    }

    // Apply filtering
    List<Map<String, dynamic>> filteredCards = sortedCards;
    if (_filterCriteria == 'priority') {
      filteredCards = sortedCards.where((card) => card['priority'] == _filterValue).toList();
    } else if (_filterCriteria == 'dueSoon') {
      final now = DateTime.now();
      filteredCards = sortedCards.where((card) {
        final dueDate = DateTime.parse(card['due_date']);
        return dueDate.difference(now).inDays <= 3;
      }).toList();
    } else if (_filterCriteria == 'status') {
      filteredCards = sortedCards.where((card) => card['status'] == _filterValue).toList();
    }

    // Group cards by status
    Map<String, List<Map<String, dynamic>>> groupedCards = {
      'TODO': [],
      'DOING': [],
      'BLOCKED': [],
      'DONE': [],
    };

    for (var card in filteredCards) {
      String status = card['status'] ?? 'TODO';
      groupedCards[status]?.add(card);
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: groupedCards.entries.map((entry) {
        if (entry.key == 'TODO') {
          return _buildBoardColumn(entry.key, Colors.black, entry.value, isTodoList: true);
        } else {
          return _buildBoardColumn(entry.key, Colors.black, entry.value);
        }
      }).toList(),
    );
  }

  // Compare priority for sorting
  int _comparePriority(String a, String b) {
    final priorityOrder = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    return priorityOrder.indexOf(b) - priorityOrder.indexOf(a);
  }

  // Build a column for each status category
  Widget _buildBoardColumn(String title, Color color, List<Map<String, dynamic>> columnCards, {bool isTodoList = false}) {
    return Container(
      width: 400,
      margin: const EdgeInsets.only(left: 16, bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                Text('${columnCards.length}', style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: columnCards.length + 1,  // +1 for the "Add a card" button
              itemBuilder: (context, index) {
                if (index < columnCards.length) {
                  var card = columnCards[index];
                  return _buildTaskCard(
                    card: card,
                    onTap: () => widget.userProfile!['is_admin'] ? _showCardDialog(context, card: card) : {},
                  );
                } else {
                  if (isTodoList && widget.userProfile!['is_admin']) {
                    return ListTile(
                      title: const Text('+ Add a card', style: TextStyle(color: Colors.blue)),
                      onTap: () => _showCardDialog(context),
                    );
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }


  // Build individual task card
  Widget _buildTaskCard({required Map<String, dynamic> card, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey[998], // Less black background
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card['title'], style: const TextStyle(fontSize: 17, color: Colors.white)),
              const SizedBox(height: 15),
              SingleChildScrollView(
                child: Row(
                  children: [
                    _buildLabel(card['priority'] ?? 'LOW'),
                    const SizedBox(width: 8,),
                    IconButton(icon: Icon(card['status'] == 'DONE' ? Icons.check_box : Icons.check,
                        size: 20,
                        color: Colors.greenAccent),
                        onPressed: () => card['status'] != 'DONE' ? _toggleTaskCompletion(card) : {}),
                    if(widget.userProfile!['is_admin'])
                      IconButton(icon: const Icon(Icons.delete_forever,
                          size: 20,
                          color: Colors.red),
                          onPressed: () async {
                            try {
                              Map<String, dynamic> result;
                              result = await _api.deleteCard(
                                cardId: card['id'],
                              );
                              if (result['success']) {
                                setState(() {
                                  _fetchBoardDetailsAndCards();
                                });
                              } else {
                                _showSnackBar('Failed to delete card');
                              }
                            } catch (e) {
                              _showSnackBar('An error occurred when deleting card');
                            }
                          }),
                    IconButton(icon: Icon(card['status'] == 'BLOCKED' ? Icons.lock_reset : Icons.lock_clock,
                        size: 20,
                        color: card['status'] != 'DONE' ? Colors.red[300] : Colors.grey),
                        onPressed: () => card['status'] == 'BLOCKED' ? _toggleStrugglingOrNot(card, 'DOING') :
                                         card['status'] == 'DOING' ? _toggleStrugglingOrNot(card, 'BLOCKED') :
                                          {}),
                    const SizedBox(width: 20,),
                    _buildDueDate(card['due_date']),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Toggle task completion status
  Future<void> _toggleTaskCompletion(Map<String, dynamic> card) async {
    try {
      Map<String, dynamic> result;
      result = await _api.updateCardStatus(
        cardId: card['id'],
        newStatus: 'DONE',
      );
      if (result['success']) {
        setState(() {
          _fetchBoardDetailsAndCards();
        });
        _showSnackBar('Well done ! Another completed task.');
      } else {
        _showSnackBar('Failed to toggled task completion');
      }
    } catch (e) {
      _showSnackBar('An error occurred when toggling task completion');
    }
  }

  // Toggle card status between BLOCKED and DOING
  Future<void> _toggleStrugglingOrNot(Map<String, dynamic> card, String newStatus) async {
    try {
      await _api.updateCardStatus(
        cardId: card['id'],
        newStatus: newStatus,
      );
      setState(() {
        _fetchBoardDetailsAndCards();
      });
    } catch (e) {
      _showSnackBar('An error occurred when toggling/untiling task struggling');
    }
  }


  // Show dialog for creating or editing a card
  void _showCardDialog(BuildContext context, {Map<String, dynamic>? card}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card != null ? 'Edit Card' : 'Create New Card', style: const TextStyle(color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: CardForm(
                card: card,
                projectStartDate: DateTime.parse(boardDetails['start_date']),
                projectDueDate: DateTime.parse(boardDetails['due_date']),
                onSubmit: (cardData) async {
                  try {
                    Map<String, dynamic> result;
                    if (card != null) {
                      result = await _api.updateCard(cardId: card['id'], updates: cardData);
                    } else {
                      result = await _api.createCard(boardId: widget.boardId, cardData: cardData);
                    }
                    if (result['success']) {
                      Navigator.of(context).pop();
                      _showSnackBar(card == null ? 'Card created successfully' : 'Card updated successfully');
                      setState(() {
                        _checkAndUpdateCardStatuses();
                        _fetchBoardDetailsAndCards();
                      });
                    } else {
                      _showSnackBar('Failed to create/update card');
                    }
                  } catch (e) {
                    _showSnackBar('An error occurred when creating/updating card'); //e.toString()
                  }
                },
              ),
            ),
          )
        );
      },
    );
  }


  // Build due date widget
  Widget _buildDueDate (String stringDueDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDueDateColor(stringDueDate),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          const Icon(Icons.timelapse, size: 15, color: Colors.black),
          Text(_formatDate(stringDueDate), style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
        ]
      )
    );
  }

  // Build due label widget
  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(label),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  // Get color based on priority
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  /*Color _getMemberColor({required String firstAndLastName}) {
    if (!membersColors.containsKey(firstAndLastName)) {
      membersColors[firstAndLastName] = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
    return membersColors[firstAndLastName]!;
  }*/


  // Get color based on due date
  Color _getDueDateColor(String dueDateString) {
    DateTime date = DateTime.parse(dueDateString);
    DateTime now = DateTime.now();
    if (now.difference(date).inHours.abs() > 48) {
      return Colors.greenAccent;
    } else if (now.difference(date).inHours.abs() > 12 && now.difference(date).inHours.abs() != 0){
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Format due dates user-friendly
  String _formatDate(String? dateString) {
    if (dateString == null) return 'No due date';
    DateTime date = DateTime.parse(dateString);
    return '${date.day}/${date.month}';
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _webSocketService.close(); // Close WebSocket connection
    super.dispose();
  }

}


// Card creation or editing form
class CardForm extends StatefulWidget {
  final Map<String, dynamic>? card;
  final Function(Map<String, dynamic>) onSubmit;
  final DateTime projectStartDate;
  final DateTime projectDueDate;

  const CardForm({
    super.key,
    this.card,
    required this.projectStartDate,
    required this.projectDueDate,
    required this.onSubmit
  });

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateTimeController;
  late TextEditingController _dueDateTimeController;
  late String _priority;
  late String _status = 'TODO';
  late List<String> _emails;
  late DateTime _startDateTime;
  late DateTime _dueDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.card?['description'] ?? '');
    _startDateTime = widget.card != null && widget.card!['start_date'] != null
        ? (DateTime.parse(widget.card!['start_date'] as String))
        : widget.projectStartDate;
    _dueDateTime = widget.card != null && widget.card!['due_date'] != null
        ? (DateTime.parse(widget.card!['due_date'] as String))
        : widget.projectDueDate;
    _startDateTimeController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(_startDateTime));
    _dueDateTimeController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(_dueDateTime));
    _priority = widget.card?['priority'] ?? 'LOW';
    _status = widget.card?['status'] ?? 'TODO';
    _emails = [];
    if (widget.card != null && widget.card!['members'] != null) {
      final members = widget.card!['members'] as List<dynamic>;
      _emails = members.map((member) => member['email'] as String).toList();
    }
  }


  Future<DateTime?> _selectDateTime(BuildContext context, {required DateTime initialDate, required DateTime firstDate, required DateTime lastDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        return dateTime;
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title, color: Colors.white),
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description, color: Colors.white),
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            maxLines: null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          TextFormField(
            readOnly: true,
            style: const TextStyle(color: Colors.white),
            controller: _startDateTimeController,
            decoration: const InputDecoration(
              labelText: 'Start Date & time',
              prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            onTap: () async {
              final DateTime? pickedDateTime = await _selectDateTime(context, initialDate: widget.projectStartDate, firstDate: widget.projectStartDate, lastDate: widget.projectDueDate,);
              if (pickedDateTime != null) {
                setState(() {
                  _startDateTime = pickedDateTime;
                  _startDateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(pickedDateTime);
                });
              }
            },
          ),
          TextFormField(
            controller: _dueDateTimeController,
            readOnly: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Due Date & time',
              prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            onTap: () async {
              final DateTime? pickedDateTime = await _selectDateTime(context, initialDate: _startDateTime, firstDate: _startDateTime, lastDate: widget.projectDueDate);
              if (pickedDateTime != null) {
                if (pickedDateTime.isAfter(_startDateTime)) {
                  setState(() {
                    _dueDateTime = pickedDateTime;
                    _dueDateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(pickedDateTime);
                  });
                }
              }
            },
          ),
          DropdownButtonFormField<String>(
            value: _priority,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Priority',
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),

              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            dropdownColor: Colors.grey[900],
            items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                .map((String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            )).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _priority = newValue!;
              });
            },
          ),
          EmailChipInputField(
            initialEmails: _emails,
            onEmailsChanged: (emails) {
              setState(() {
                _emails.clear();
                _emails.addAll(emails);
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit({
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'start_date': _startDateTime.toIso8601String(),
                    'due_date': _dueDateTime.toIso8601String(),
                    'priority': _priority,
                    'status': _status,
                    'emails': _emails,
                  });
                }
              },
              child: Text(widget.card == null ? 'Create Card' : 'Update Card'),
            ),
          )
        ],
      ),
    );
  }
}




class EmailChipInputField extends StatefulWidget {
  final List<String> initialEmails;
  final ValueChanged<List<String>> onEmailsChanged;

  const EmailChipInputField({
    super.key,
    this.initialEmails = const [],
    required this.onEmailsChanged,
  });

  @override
  State<EmailChipInputField> createState() => _EmailChipInputFieldState();
}

class _EmailChipInputFieldState extends State<EmailChipInputField> {
  final List<String> _emails = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emails.addAll(widget.initialEmails);
  }

  void _addEmail(String email) {
    if (email.isNotEmpty && email.contains('@')) {
      setState(() {
        _emails.add(email);
        _controller.clear();
      });
      widget.onEmailsChanged(_emails);
    }
  }

  void _removeEmail(String email) {
    setState(() {
      _emails.remove(email);
    });
    widget.onEmailsChanged(_emails);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ..._emails.map((email) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade300,
                  child: Text(email[0].toUpperCase()),
                ),
                label: Text(email),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeEmail(email),
              )),
            ],
          ),
          TextFormField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'Enter email addresses',
              hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
              prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            onFieldSubmitted: (value) {
              _addEmail(value);
              _focusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}