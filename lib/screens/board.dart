import 'package:flutter/material.dart';
import '../services/api.dart';
import 'dart:math';

class BoardScreen extends StatefulWidget {
  final int boardId;

  const BoardScreen({Key? key, required this.boardId}) : super(key: key);

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(boardDetails['pic']), // Replace with your image path
            fit: BoxFit.cover, // Adjust the fit as needed
          ),
        ),
        child: Center( // Your content here
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
            children: [
              SizedBox(height: 15),
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
      width: 380,
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
                    card['title'] ?? 'Untitled',
                    card['priority'] ?? 'LOW',
                    card['due_date'],
                    card['members'] ?? [],
                  );
                } else {
                  return ListTile(
                    title: Text('+ Add a card', style: TextStyle(color: Colors.blue)),
                    onTap: () {
                      // Implement add card functionality
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTaskCard(String title, String priority, String dueDate, List<dynamic> members) {
    return Container(
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
            Text(title, style: TextStyle(fontSize: 17, color: Colors.white)),
            SizedBox(height: 8),
            Row(
              children: [
                _buildDueDate(dueDate),
                SizedBox(width: 6),
                _buildLabel(priority),
                IconButton(onPressed: () => {}, icon: Icon(Icons.check_box_outlined, size: 20, color: Colors.grey[200])),
                IconButton(onPressed: () => {}, icon: Icon(Icons.cancel_outlined, size: 20, color: Colors.grey[200])),
                Spacer(),
                CircleAvatar(radius: 10, backgroundColor: Colors.grey[300]),
              ],
            ),
          ],
        ),
      ),
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
          Icon(Icons.timelapse, size: 16, color: Colors.black),
          Text(_formatDate(stringDueDate), style: TextStyle(fontSize: 12, color: Colors.black)),
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
      child: Text(label, style: TextStyle(fontSize: 12)),
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
