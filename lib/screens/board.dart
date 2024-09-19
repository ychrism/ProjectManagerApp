import 'package:flutter/material.dart';

class BoardScreen extends StatelessWidget {
  final String? boardName;

  BoardScreen({this.boardName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(boardName ?? 'Board'),
        backgroundColor: Colors.blue,
      ),
      body: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTaskColumn('To-Do', Colors.black),
          _buildTaskColumn('Doing', Colors.black),
          _buildTaskColumn('Blocked', Colors.black),
          _buildTaskColumn('Done', Colors.black),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Create new card logic
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        heroTag: 'addCard',
      ),
    );
  }

  Widget _buildTaskColumn(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.all(30.5),
      child: Container(
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: [
                  _buildTaskCard('Task 1', 'High', '2024-09-30', ["Yves MEDAGBE", "François MEDAGBE"]),
                  _buildTaskCard('Task 2', 'Medium', '2024-10-05', ["Yves MEDAGBE", "François MEDAGBE"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(String taskTitle, String priority, String dueDate, List<String> members) {
    // Function to determine the due date color (red if imminent, otherwise gray)
    Color _getDueDateColor(String dueDate) {
      return DateTime.parse(dueDate).isBefore(DateTime.now()) ? Colors.red : Colors.green;
    }

    // Limit avatars to a maximum of 6, with extra indicator if more than 6
    List<Widget> _buildMemberAvatars(List<String> members) {
      List<Widget> avatars = members.take(6).map((member) {
        return CircleAvatar(
          radius: 12,
          backgroundColor: Colors.blue,
          child: Text(
            member[0], // Use the first letter as the avatar's label
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }).toList();

      if (members.length > 6) {
        avatars.add(CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey,
          child: const Text(
            '...',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ));
      }
      return avatars;
    }

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date in a colored box
                Container(

                  decoration: BoxDecoration(
                    color: _getDueDateColor(dueDate),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Due: ${DateTime.parse(dueDate).toLocal().toString()}', // Show due date
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                // "Done" and "Blocked" buttons with checkboxes
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Mark as done
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Done'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.green,
                        minimumSize: const Size(70, 30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Mark as blocked
                      },
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Blocked'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(90, 30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Overlapping member avatars
            Row(
              children: _buildMemberAvatars(members),
            ),
          ],
        ),
      ),
    );
  }

}
