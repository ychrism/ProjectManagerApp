import 'dart:collection';

import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class BoardScreen extends StatefulWidget {
  final int boardId;

  const BoardScreen({Key? key, required this.boardId}) : super(key: key);

  @override
  BoardScreenState createState() => BoardScreenState();
}

class BoardScreenState extends State<BoardScreen> {
  final Api _api = Api();
  List<Map<String, dynamic>> cards = [];
  Map<String, dynamic> boardDetails = {};
  bool isLoading = true;
  final Map<String, Color> membersColors = {};

  @override
  void initState() {
    super.initState();
    _fetchBoardDetailsAndCards();
  }

  @override
  void didUpdateWidget(BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardId != widget.boardId) {
      _fetchBoardDetailsAndCards();
    }
  }

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
      _showSnackBar('Failed to fetch data: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 50,
        title: Row(
          children: [
            Text(boardDetails['name'] ?? 'Loading...', style: TextStyle(color: Colors.white)),
            //Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list_alt, color: Colors.white), onPressed: () {}),
        ],
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(boardDetails['pic']), // Replace with your image path
            fit: BoxFit.cover, // Adjust the fit as needed
          ),
        ),
        child: Center( // Your content here
          child: Column(
            children: [
              SizedBox(height: 13),
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

  Widget _buildMemberAvatars() {
    return Container(
      height: 45,
      width: 200,
      margin: EdgeInsets.only(right: 300),
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

  Widget _buildAvatar(Color color, {String? label}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: CircleAvatar(
        backgroundColor: color,
        child: label != null ? Text(label, style: TextStyle(color: Colors.white)) : null,
      ),
    );
  }


  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 16,
                borderRadius: BorderRadius.circular(18),
              ),
              Text('70%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardList() {
    // Group cards by status
    Map<String, List<Map<String, dynamic>>> groupedCards = {
      'TODO': [],
      'DOING': [],
      'BLOCKED': [],
      'DONE': [],
    };

    for (var card in cards) {
      String status = card['status'] ?? 'TODO';
      groupedCards[status]?.add(card);
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      children: groupedCards.entries.map((entry) {
        return _buildBoardColumn(entry.key, Colors.black, entry.value);
      }).toList(),
    );
  }

  Widget _buildBoardColumn(String title, Color color, List<Map<String, dynamic>> columnCards) {
    return Container(
      width: 400,
      margin: EdgeInsets.only(left: 16, bottom: 16),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                Text('${columnCards.length}', style: TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: columnCards.length + 1,  // +1 for the "Add a card" button
              itemBuilder: (context, index) {
                if (index < columnCards.length) {
                  var card = columnCards[index];
                  return _buildTaskCard(
                    card: card,
                    onTap: () => _showCardDialog(context, card: card),
                  );
                } else {
                  return ListTile(
                    title: Text('+ Add a card', style: TextStyle(color: Colors.blue)),
                    onTap: () => _showCardDialog(context),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTaskCard({required Map<String, dynamic> card, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey[998], // Less black background
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card['title'], style: TextStyle(fontSize: 17, color: Colors.white)),
              SizedBox(height: 15),
              SingleChildScrollView(
                child: Row(
                  children: [
                    _buildLabel(card['priority'] ?? 'LOW'),
                    SizedBox(width: 8,),
                    IconButton(icon: Icon(card['status'] == 'DONE' ? Icons.check_box : Icons.check,
                        size: 20,
                        color: Colors.greenAccent),
                        onPressed: () => card['status'] != 'DONE' ? _toggleTaskCompletion(card) : {}),
                    IconButton(icon: Icon(Icons.delete_forever,
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
                              _showSnackBar(result['error']);
                            }
                          } catch (e) {
                            _showSnackBar('Failed to update card status: ${e.toString()}');
                          }
                        }),
                    IconButton(icon: Icon(card['status'] == 'BLOCKED' ? Icons.lock_reset : Icons.lock_clock,
                        size: 20,
                        color: card['status'] != 'DONE' ? Colors.red[300] : Colors.grey),
                        onPressed: () => card['status'] == 'BLOCKED' ? _toggleStrugglingOrNot(card, 'DOING') :
                                         card['status'] == 'DOING' ? _toggleStrugglingOrNot(card, 'BLOCKED') :
                                          {}),
                    SizedBox(width: 20,),
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
        _showSnackBar(result['error']);
      }
    } catch (e) {
      _showSnackBar('Failed to update card status: ${e.toString()}');
    }
  }

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
      _showSnackBar('Failed to update card status: ${e.toString()}');
    }
  }


  void _showCardDialog(BuildContext context, {Map<String, dynamic>? card}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(card != null ? 'Edit Card' : 'Create New Card', style: TextStyle(color: Colors.white)),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              child: CardForm(
                card: card,
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
                        _fetchBoardDetailsAndCards();
                      });
                    } else {
                      _showSnackBar(result['error']);
                    }
                  } catch (e) {
                    _showSnackBar(e.toString());
                  }
                },
              ),
            ),
          )
        );
      },
    );
  }


  Widget _buildDueDate (String stringDueDate) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDueDateColor(stringDueDate),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Icon(Icons.timelapse, size: 15, color: Colors.black),
          Text(_formatDate(stringDueDate), style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
        ]
      ) 
    );
  }
  
  Widget _buildLabel(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(label),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

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

  Color _getMemberColor({required String firstAndLastName}) {
    if (!membersColors.containsKey(firstAndLastName)) {
      membersColors[firstAndLastName] = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    }
    return membersColors[firstAndLastName]!;
  }

  Color _getDueDateColor(String dueDateString) {
    DateTime date = DateTime.parse(dueDateString).toUtc().add(DateTime.now().timeZoneOffset);
    DateTime now = DateTime.now().toUtc().add(DateTime.now().timeZoneOffset);
    if (now.difference(date).inHours.abs() > 48) {
      return Colors.greenAccent;
    } else if (now.difference(date).inHours.abs() > 12 && now.difference(date).inHours.abs() != 0){
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No due date';
    DateTime date = DateTime.parse(dateString).toUtc().add(DateTime.now().timeZoneOffset);
    return '${date.day}/${date.month}';
  }

}


class CardForm extends StatefulWidget {
  final Map<String, dynamic>? card;
  final Function(Map<String, dynamic>) onSubmit;

  const CardForm({Key? key, this.card, required this.onSubmit}) : super(key: key);

  @override
  _CardFormState createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateTimeController;
  late TextEditingController _dueDateTimeController;
  String _priority = 'LOW';
  String _status = 'TODO';
  late List<String> _emails;
  late DateTime _startDateTime;
  late DateTime _dueDateTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.card?['description'] ?? '');
    _startDateTime = widget.card != null && widget.card!['start_date'] != null
        ? (DateTime.parse(widget.card!['start_date'] as String)).toUtc().add(DateTime.now().timeZoneOffset)
        : DateTime.now().toUtc().add(DateTime.now().timeZoneOffset);
    _dueDateTime = widget.card != null && widget.card!['due_date'] != null
        ? (DateTime.parse(widget.card!['due_date'] as String)).toUtc().add(DateTime.now().timeZoneOffset)
        : DateTime.now().add(Duration(days: 1)).toUtc().add(DateTime.now().timeZoneOffset);
    _startDateTimeController = TextEditingController(text: widget.card?['start_date'] ?? DateFormat('yyyy-MM-dd HH:mm').format(_startDateTime));
    _dueDateTimeController = TextEditingController(text: widget.card?['due_date'] ?? DateFormat('yyyy-MM-dd HH:mm').format(_dueDateTime));
    _priority = widget.card?['priority'] ?? 'LOW';
    _status = widget.card?['status'] ?? 'TODO';
    _emails = [];
    if (widget.card != null && widget.card!['members'] != null) {
      final members = widget.card!['members'] as List<dynamic>;
      _emails = members.map((member) => member['email'] as String).toList();
    }
  }


  Future<DateTime?> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final dateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final timezoneOffset = DateTime.now().timeZoneOffset;
        return dateTime.toUtc().add(timezoneOffset);
      }
    }
    return null;
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
            style: TextStyle(color: Colors.white),
            controller: _startDateTimeController,
            decoration: InputDecoration(
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
              final DateTime? pickedDateTime = await _selectDateTime(context);
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
              final DateTime? pickedDateTime = await _selectDateTime(context);
              if (pickedDateTime != null) {
                if (pickedDateTime.isAfter(_startDateTime)) {
                  setState(() {
                    _dueDateTime = pickedDateTime;
                    _dueDateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(pickedDateTime);
                  });
                } else {
                  _showSnackBar('Due date must be after start date');
                }
              }
            },
          ),
          DropdownButtonFormField<String>(
            value: _priority,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
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
          DropdownButtonFormField<String>(
            value: _status,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),

              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            dropdownColor: Colors.grey[900],
            items: ['TODO', 'DOING', 'BLOCKED', 'DONE']
                .map((String value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            ))
                .toList(),
            onChanged: (String? newValue) {
              setState(() {
                _status = newValue!;
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
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: Text(widget.card == null ? 'Create Card' : 'Update Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit({
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'start_date': _startDateTime,
                    'due_date': _dueDateTime,
                    'priority': _priority,
                    'status': _status,
                    'emails': _emails,
                  });
                }
              },
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
    Key? key,
    this.initialEmails = const [],
    required this.onEmailsChanged,
  }) : super(key: key);

  @override
  _EmailChipInputFieldState createState() => _EmailChipInputFieldState();
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
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () => _removeEmail(email),
              )),
            ],
          ),
          TextFormField(
            controller: _controller,
            style: TextStyle(color: Colors.white),
            focusNode: _focusNode,
            decoration: InputDecoration(
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