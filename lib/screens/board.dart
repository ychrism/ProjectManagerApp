import 'package:flutter/material.dart';

class BoardScreen extends StatelessWidget {
  final int boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context) {
    // Use the boardId to fetch and display the specific board data
    return Scaffold(
      appBar: AppBar(
        elevation: 50,
        title: Row(
          children: [
            Text('Board $boardId', style: TextStyle(color: Colors.white),),
            Icon(Icons.arrow_drop_down, color: Colors.white,),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: Colors.white,), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list_alt, color: Colors.white,), onPressed: () {}),
        ],
        backgroundColor: Colors.black,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          _buildMemberAvatars(),
          _buildProgressBar(),
          Expanded(
            child: _buildBoardList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatars() {
    return Container(
      height: 50,
      width: 400,
      //margin: EdgeInsets.only(right: 20),
      child: Stack(
        children: [
          Positioned(left: 10, child: _buildAvatar(Colors.blue)),
          Positioned(left: 40, child: _buildAvatar(Colors.green)),
          Positioned(left: 70, child: _buildAvatar(Colors.orange)),
          Positioned(left: 100, child: _buildAvatar(Colors.purple)),
          Positioned(left: 130, child: _buildAvatar(Colors.grey, label: '+5')),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, {String? label}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
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
          Text(
            'Overall',
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 16,
                borderRadius: BorderRadius.circular(18),
              ),
              Text('70%', style: TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardList() {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _buildBoardColumn('TODO', Colors.black, 4),
        _buildBoardColumn('DOING', Colors.black, 3),
        _buildBoardColumn('BLOCKED', Colors.black, 2),
        _buildBoardColumn('DONE', Colors.black, 5),
      ],
    );
  }

  Widget _buildBoardColumn(String title, Color color, int cardCount) {
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('$cardCount', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          SizedBox(
            height: 600, // Reduced height
            child: ListView(
              padding: EdgeInsets.all(8),
              children: [
                ...List.generate(
                  cardCount,
                      (index) => _buildTaskCard('Task ${index + 1}', 'Label', 3, 1, '0/3'),
                ),
                ListTile(
                  title: Text('+ Add a card', style: TextStyle(color: Colors.blue)),
                  onTap: () {
                    // Implement add card functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String label, int attachments, int comments, String progress) {
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
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),

            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey),
                Text('$attachments', style: TextStyle(color: Colors.grey)),
                SizedBox(width: 8),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                Text('$comments', style: TextStyle(color: Colors.grey)),
                SizedBox(width: 8),
                Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                Text(progress, style: TextStyle(color: Colors.grey)),
                SizedBox(width: 8),
                Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                Text(progress, style: TextStyle(color: Colors.grey)),
                SizedBox(width: 8),
                _buildLabel(label),
                Spacer(),
                CircleAvatar(radius: 10, backgroundColor: Colors.grey[300]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
}