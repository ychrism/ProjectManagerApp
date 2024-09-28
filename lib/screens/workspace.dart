import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'board.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../services/api.dart';

class WorkspaceScreen extends StatefulWidget {
  final Function(int) onBoardSelected;

  const WorkspaceScreen({Key? key, required this.onBoardSelected}) : super(key: key);

  @override
  WorkspaceScreenState createState() => WorkspaceScreenState();
}

class WorkspaceScreenState extends State<WorkspaceScreen> {
  final Api _api = Api();
  List<Map<String, dynamic>> boards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchBoards();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.photos.status;
    if (status.isDenied) {
      await Permission.photos.request();
    }
  }

  Future<void> _fetchBoards() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedBoards = await _api.fetchBoards();
      setState(() {
        boards = fetchedBoards;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to fetch boards: ${e.toString()}');
    }
  }

  void _showBoardPopup(BuildContext context, {Map<String, dynamic>? boardToEdit}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext innerContext) {
            return AlertDialog(
                backgroundColor: Colors.grey[800],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(boardToEdit != null ? 'Edit Board' : 'New Board', style: TextStyle(color: Colors.white)),
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
                    child: BoardForm(
                      boardToEdit: boardToEdit,
                      onSubmit: (boardData) async {
                        try {
                          Map<String, dynamic> result;
                          if (boardToEdit != null) {
                            result = await _api.updateBoard(
                              boardId: boardToEdit['id'],
                              updates: {
                                'name': boardData['name'],
                                'start_date': boardData['startDateTime'],
                                'due_date': boardData['dueDateTime'],
                                'description': boardData['description'],
                                'pic': boardData['pic'],
                              }
                            );
                          } else {
                            result = await _api.createBoard(
                              name: boardData['name'],
                              startDate: boardData['startDateTime'],
                              dueDate: boardData['dueDateTime'],
                              description: boardData['description'],
                              imageData: boardData['pic'],
                            );
                          }

                          if (result['success']) {
                            Navigator.of(context).pop();
                            _showSnackBar(boardToEdit != null ? 'Board updated successfully' : 'Board created successfully');
                            setState(() {
                              _fetchBoards(); // Refresh the board list
                            });
                          } else {
                            _showSnackBar(result['error']);
                          }
                        } catch (e) {
                          _showSnackBar('An error occurred. Please try again.');
                        }
                      },
                    ),
                  ),
                )
            );
          },
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> board) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showBoardPopup(context, boardToEdit: board);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteBoard(board['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteBoard(int boardId) async {
    try {
      final result = await _api.deleteBoard(boardId: boardId);
      if (result['success']) {
        _showSnackBar('Board deleted successfully');
        setState(() {
          _fetchBoards(); // Refresh the board list
        });
      } else {
        _showSnackBar(result['error']);
      }
    } catch (e) {
      _showSnackBar(
          'An error occurred while deleting the board. Please try again.');
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
        title: const Row(
          children: [
            Text(
              'TaskFlow',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 40),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.search, color: Colors.white,), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list, color: Colors.white,), onPressed: () {}),
          IconButton(icon: Icon(Icons.share, color: Colors.white,), onPressed: () {}),
        ],
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: boards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final board = boards[index];
                return GestureDetector(
                  onTap: () {
                    widget.onBoardSelected(board['id']);
                  },
                  onLongPress: () {
                    _showContextMenu(context, board);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(board['pic']),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        board['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showBoardPopup(context);
              },
              backgroundColor: Colors.lightBlue,
              label: Text('Add Board', style: TextStyle(color: Colors.white, fontSize: 20)),
              icon: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}


class BoardForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? boardToEdit;

  const BoardForm({Key? key, required this.onSubmit, this.boardToEdit}) : super(key: key);

  @override
  BoardFormState createState() => BoardFormState();
}

class BoardFormState extends State<BoardForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageController;
  late final TextEditingController _startDateTimeController;
  late final TextEditingController _dueDateTimeController;

  late DateTime _startDateTime;
  late DateTime _dueDateTime;
  File? _imageFile;
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    final board = widget.boardToEdit;
    _nameController = TextEditingController(text: board?['name'] ?? '');
    _descriptionController = TextEditingController(text: board?['description'] ?? '');
    _existingImagePath = board?['pic'];
    _imageController = TextEditingController(text: _getImageFileName(_existingImagePath));
    _startDateTime = board != null && board['start_date'] != null
        ? (DateTime.parse(board['start_date'] as String)).toUtc().add(DateTime.now().timeZoneOffset)
        : DateTime.now().toUtc().add(DateTime.now().timeZoneOffset);
    _dueDateTime = board != null && board['due_date'] != null
        ? (DateTime.parse(board['due_date'] as String)).toUtc().add(DateTime.now().timeZoneOffset)
        : DateTime.now().add(Duration(days: 1)).toUtc().add(DateTime.now().timeZoneOffset);
    _startDateTimeController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(_startDateTime));
    _dueDateTimeController = TextEditingController(text: DateFormat('yyyy-MM-dd HH:mm').format(_dueDateTime));
  }

  String _getImageFileName(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return path.basename(imagePath);
  }

  Future<void> _pickImage() async {
    var status = await Permission.photos.status;
    if (status.isGranted) {
      final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
          _imageController.text = path.basename(pickedImage.path);
          _existingImagePath = null;
        });
      }
    } else {
      _showSnackBar('Please grant access to your media first');
      await Permission.photos.request();
    }
  }

  bool isValidFileExtension(String name) {
    final extension = path.extension(name).toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png'];
    return allowedExtensions.contains(extension);
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

  Future<void> _pickStartDateTime(BuildContext context) async {
    final DateTime? pickedDateTime = await _selectDateTime(context);
    if (pickedDateTime != null) {
      setState(() {
        _startDateTime = pickedDateTime;
        _startDateTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(pickedDateTime);
      });
    }
  }

  Future<void> _pickDueDateTime(BuildContext context) async {
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
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final imageData = _imageFile != null
          ? {'file': _imageFile, 'fileName': path.basename(_imageFile!.path)}
          : (_existingImagePath != null ? {'existingPath': _existingImagePath} : null);

      widget.onSubmit({
        'name': _nameController.text,
        'startDateTime': _startDateTime,
        'dueDateTime': _dueDateTime,
        'description': _descriptionController.text,
        'pic': imageData,
      });
    }
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
          _buildTextFormField(
            controller: _nameController,
            labelText: 'Name',
            prefixIcon: Icon(Icons.title, color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          _buildTextFormField(
            controller: _descriptionController,
            labelText: 'Description',
            prefixIcon: Icon(Icons.description, color: Colors.white),
            maxLines: null,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          _buildTextFormField(
            controller: _imageController,
            labelText: 'Background Image',
            prefixIcon: Icon(Icons.image, color: Colors.white),
            suffixIcon: Icon(Icons.attach_file, color: Colors.white),
            onTap: _pickImage,
            readOnly: true,
            validator: (value) {
              if (_imageFile == null && _existingImagePath == null) {
                return 'Please choose an image file for your board';
              }
              if (_imageFile != null && !isValidFileExtension(_imageFile!.path)) {
                return 'Please choose a PNG or JPEG image file';
              }
              return null;
            },
          ),
          _buildTextFormField(
            readOnly: true,
            controller: _startDateTimeController,
            labelText: 'Start DateTime',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
            onTap: () => _pickStartDateTime(context),
          ),
          _buildTextFormField(
            controller: _dueDateTimeController,
            labelText: 'Due DateTime',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white),
            readOnly: true,
            onTap: () => _pickDueDateTime(context),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.boardToEdit != null ? 'Update Board' : 'Create Board'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required Icon? prefixIcon,
    Icon? suffixIcon,
    int? maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      readOnly: readOnly,
      style: TextStyle(color: Colors.white),
      maxLines: null,
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      onTap: onTap,
      validator: validator,
    );
  }
}