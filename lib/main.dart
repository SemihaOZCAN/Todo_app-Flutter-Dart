import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class Category {
  final String name;

  Category(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class Todo {
  String task;
  Category category;
  bool isCompleted;

  Todo({
    required this.task,
    required this.category,
    this.isCompleted = false,
  });
}

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yapılacaklar Listesi',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
        ),
      ),
      locale: Locale('tr', 'TR'),
      supportedLocales: [Locale('tr', 'TR')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  List<Category> categories = [
    Category('Kişisel'),
    Category('İş'),
    Category('Okul'),
  ];

  List<Todo> todos = [];
  Category? _selectedCategory;
  String _searchQuery = '';

  final TextEditingController _textFieldController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
    FlutterNativeSplash.remove();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTodos = prefs.getStringList('todos') ?? [];
    final savedCategories = prefs.getStringList('categories') ?? [];

    setState(() {
      categories = savedCategories.map((name) => Category(name)).toList();
      todos = savedTodos.map((item) {
        final parts = item.split('|');
        return Todo(
          task: parts[0],
          category: categories.firstWhere(
            (cat) => cat.name == parts[1],
            orElse: () => Category('Diğer'),
          ),
          isCompleted: parts.length > 2 ? parts[2] == 'true' : false,
        );
      }).toList();
    });
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTodos = todos.map((todo) {
      return '${todo.task}|${todo.category.name}|${todo.isCompleted}';
    }).toList();
    prefs.setStringList('todos', savedTodos);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = categories.map((cat) => cat.name).toList();
    prefs.setStringList('categories', savedCategories);
  }

  void _addTodoItem(String task, Category category) {
    if (task.isNotEmpty) {
      setState(() {
        todos.add(Todo(
          task: task,
          category: category,
        ));
        _saveTodos();
      });
    }
  }

  Future<void> _displayAddTodoDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Görev Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textFieldController,
                decoration: InputDecoration(hintText: 'Görev girin'),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
              DropdownButton<Category>(
                value: _selectedCategory,
                hint: Text('Kategori seçin'),
                items: categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (Category? category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ekle'),
              onPressed: () {
                if (_selectedCategory != null) {
                  _addTodoItem(_textFieldController.text, _selectedCategory!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori seçiniz')),
                  );
                }
              },
            ),
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _displayEditTodoDialog(BuildContext context, int index) async {
    final TextEditingController _editController = TextEditingController(text: todos[index].task);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Görevi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editController,
                decoration: InputDecoration(hintText: 'Görevi güncelleyin'),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
              DropdownButton<Category>(
                value: todos[index].category,
                hint: Text('Kategori seçin'),
                items: categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (Category? category) {
                  setState(() {
                    if (category != null) {
                      todos[index].category = category;
                    }
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Güncelle'),
              onPressed: () {
                setState(() {
                  todos[index].task = _editController.text;
                });
                _saveTodos();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeTodoItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Onay'),
          content: Text('Bu görevi silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('Evet'),
              onPressed: () {
                setState(() {
                  todos.removeAt(index);
                });
                _saveTodos();
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              child: Text('Hayır'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTodoCompletion(int index) {
    setState(() {
      todos[index].isCompleted = !todos[index].isCompleted;
      _saveTodos();
    });
  }

  void _addCategory() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Kategori Ekle'),
          content: TextField(
            controller: _categoryController,
            decoration: InputDecoration(hintText: 'Kategori adı girin'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ekle'),
              onPressed: () {
                final newCategoryName = _categoryController.text.trim();
                if (newCategoryName.isNotEmpty) {
                  setState(() {
                    final newCategory = Category(newCategoryName);
                    categories.add(newCategory);
                    _saveCategories();
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeCategory(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Onay'),
          content: Text('Bu kategoriyi silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: Text('Evet'),
              onPressed: () {
                setState(() {
                  if (_selectedCategory == categories[index]) {
                    _selectedCategory = null; 
                  }
                  categories.removeAt(index);
                  _saveCategories();
                });
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              child: Text('Hayır'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodos = todos.where((todo) {
      return todo.task.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Yapılacaklar Listesi'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addCategory,
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Görev Ara',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          Expanded(
            child: filteredTodos.isEmpty
                ? Center(child: Text('Görev bulunamadı.'))
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          filteredTodos[index].task,
                          style: TextStyle(
                            decoration: filteredTodos[index].isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(filteredTodos[index].category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: filteredTodos[index].isCompleted,
                              onChanged: (value) {
                                _toggleTodoCompletion(todos.indexOf(filteredTodos[index]));
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removeTodoItem(todos.indexOf(filteredTodos[index]));
                              },
                            ),
                          ],
                        ),
                        onTap: () => _displayEditTodoDialog(context, todos.indexOf(filteredTodos[index])),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Kategoriler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categories[index].name),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeCategory(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), // Butonu yukarı almak için yukarıdan boşluk bırak
        child: FloatingActionButton(
          onPressed: () => _displayAddTodoDialog(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}