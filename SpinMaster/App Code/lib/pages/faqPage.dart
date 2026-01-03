import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  static const List<Map<String, String>> faqs = [
    {
      "question": "What is a wheel decide tool?",
      "answer":
          "A wheel decide tool is a digital tool that allows users to generate random outcomes by spinning a virtual wheel. The wheel typically consists of a circular platform with a series of options or choices arranged around the circumference. Users can spin the wheel by clicking a button or dragging the wheel with their mouse, and the tool will randomly stop on one of the options.",
    },
    {
      "question": "How does a SpinMaster work?",
      "answer":
          "A SpinMaster is similar to a wheel decide tool, in that it allows users to generate random outcomes by spinning a virtual object. In the case of a SpinMaster, the object is typically a spinner or a set of pointers that can be spun by clicking a button or dragging with the mouse. The tool will stop on a random outcome when the spinning stops.",
    },
    {
      "question":
          "Can I customize the options on a wheel decide or SpinMaster?",
      "answer":
          "In most cases, yes. Most wheel decide and SpinMasters allow users to customize the options available on the wheel or spinner by adding or removing items from a list. Some tools may also allow users to customize the appearance of the wheel or spinner, as well as the number of spins and the speed at which it spins.",
    },
    {
      "question": "Can I use a wheel decide or SpinMaster for decision-making?",
      "answer":
          "Yes, wheel decide and SpinMasters can be useful tools for decision-making. You can add the different options you're considering to the wheel or spinner.",
    },
  ];

  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FAQ'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return FAQItem(
              question: faq["question"]!,
              answer: faq["answer"]!,
              index: index + 1,
            );
          },
        ),
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final int index;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
    required this.index,
  });

  @override
  _FAQItemState createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          leading: CircleAvatar(
            backgroundColor: Colors.blue[700],
            child: Text(
              '${widget.index}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            widget.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          collapsedIconColor: Colors.blue[800],
          iconColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              color: Colors.blue[50],
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
