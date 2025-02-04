import 'package:flutter/material.dart';
import 'package:mp3/models/data_manager.dart';
import 'package:mp3/models/quiz_screen.dart';
import 'package:mp3/utils/db_helper.dart';

class FlashcardListScreen extends StatefulWidget {
  final Decktable deck;

  const FlashcardListScreen({Key? key, required this.deck}) : super(key: key);

  @override
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  List<Flashcardtable> flashcards = [];
  String currentSortType = 'alphabetical';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          IconButton(
  icon: const Icon(Icons.sort_by_alpha),
  onPressed: () {
    setState(() {
      currentSortType = 'alphabetical';
      fetchSortedFlashcards(widget.deck.id!, currentSortType);
    });
  },
),
        ],
      ),
      body: FutureBuilder<List<Flashcardtable>>(
        future: fetchFlashcardsForDeck(widget.deck.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No flashcards available for ${widget.deck.title}.'),
            );
          } else {
            flashcards = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200.0,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
              ),
              itemCount: flashcards.length,
              itemBuilder: (context, index) {
                final flashcard = flashcards[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(flashcard: flashcard),
                      ),
                    );
                  },
                  child: FlashcardItem(flashcard),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddFlashcardScreen(deck: widget.deck),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<Flashcardtable>> fetchFlashcardsForDeck(int deckId) async {
    final dbHelper = DBHelper();
    final db = await dbHelper.db;

    final List<Map<String, dynamic>> flashcardMaps =
        await db.query('flashcards', where: 'deck_id = ?', whereArgs: [deckId]);

    return List.generate(flashcardMaps.length, (i) {
      return Flashcardtable(
        id: flashcardMaps[i]['id'],
        deck_id: flashcardMaps[i]['deck_id'],
        question: flashcardMaps[i]['question'],
        answer: flashcardMaps[i]['answer'],
      );
    });
  }
Future<void> fetchSortedFlashcards(int deckId, String sortType) async {
  final dbHelper = DBHelper();
  final db = await dbHelper.db;
  List<Map<String, dynamic>> flashcardMaps = await db.query(
    'flashcards',
    where: 'deck_id = ?',
    whereArgs: [deckId],
  );

  // Convert the query result to a modifiable list
  List<Map<String, dynamic>> modifiableFlashcardMaps = List.from(flashcardMaps);

  // Sorting the flashcardMaps list by the question field.
  modifiableFlashcardMaps.sort((a, b) => a['question'].compareTo(b['question']));

  // Convert the sorted map list to a list of Flashcardtable objects.
  List<Flashcardtable> sortedFlashcards = modifiableFlashcardMaps.map((map) {
    return Flashcardtable(
      id: map['id'],
      deck_id: map['deck_id'],
      question: map['question'],
      answer: map['answer'],
    );
  }).toList();

  setState(() {
    flashcards = sortedFlashcards;
  });
}

}

class FlashcardItem extends StatelessWidget {
  final Flashcardtable flashcard;

  const FlashcardItem(this.flashcard, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 130, 215, 255),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children:
          [
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    flashcard.question,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FlashcardDetailScreen(flashcard: flashcard),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class AddFlashcardScreen extends StatefulWidget {
  final Decktable deck;

  const AddFlashcardScreen({Key? key, required this.deck}) : super(key: key);

  @override
  _AddFlashcardScreenState createState() => _AddFlashcardScreenState();
}

class _AddFlashcardScreenState extends State<AddFlashcardScreen> {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Flashcard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Add a new flashcard for ${widget.deck.title}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.insert('flashcards', {
                        'deck_id': widget.deck.id,
                        'question': questionController.text,
                        'answer': answerController.text,
                      });

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardListScreen(deck: widget.deck),
                        ),
                      );
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashcardDetailScreen extends StatefulWidget {
  final Flashcardtable flashcard;

  const FlashcardDetailScreen({Key? key, required this.flashcard}) : super(key: key);

  @override
  _FlashcardDetailScreenState createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  TextEditingController questionController = TextEditingController();
  TextEditingController answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    questionController.text = widget.flashcard.question;
    answerController.text = widget.flashcard.answer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Detail'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Question:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.update('flashcards', {
                        'id': widget.flashcard.id,
                        'question': questionController.text,
                        'answer': answerController.text,
                      });

                      Navigator.pop(context, 'updated');
                    },
                    child: const Text('Save', style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () async {
                      final dbHelper = DBHelper();
                      await dbHelper.delete('flashcards', widget.flashcard.id!);

                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
