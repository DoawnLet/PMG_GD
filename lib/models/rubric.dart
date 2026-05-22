class Criterion {
  final String id;
  final String name;
  final double maxPoints;
  final String fullDesc;
  final String acceptDesc;
  final String failDesc;

  const Criterion({
    required this.id,
    required this.name,
    required this.maxPoints,
    required this.fullDesc,
    required this.acceptDesc,
    required this.failDesc,
  });

  factory Criterion.fromJson(Map<String, dynamic> j) => Criterion(
    id: j['id'] as String,
    name: j['name'] as String,
    maxPoints: (j['maxPoints'] as num).toDouble(),
    fullDesc: j['fullDesc'] as String,
    acceptDesc: j['acceptDesc'] as String,
    failDesc: j['failDesc'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'maxPoints': maxPoints,
    'fullDesc': fullDesc,
    'acceptDesc': acceptDesc,
    'failDesc': failDesc,
  };
}

class RequestRubric {
  final int number;
  final String title;
  final double maxPoints;

  final String description;
  final List<Criterion> criteria;
  final List<String> commonErrors;

  const RequestRubric({
    required this.number,
    required this.title,
    required this.maxPoints,

    this.description = '',
    required this.criteria,
    required this.commonErrors,
  });

  factory RequestRubric.fromJson(Map<String, dynamic> j) => RequestRubric(
    number: j['number'] as int,
    title: j['title'] as String,
    maxPoints: (j['maxPoints'] as num).toDouble(),
    description: j['description'] as String? ?? '',
    criteria: (j['criteria'] as List)
        .map((c) => Criterion.fromJson(c as Map<String, dynamic>))
        .toList(),
    commonErrors: (j['commonErrors'] as List).map((e) => e as String).toList(),
  );

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'maxPoints': maxPoints,

    'description': description,
    'criteria': criteria.map((c) => c.toJson()).toList(),
    'commonErrors': commonErrors,
  };
}

class Rubric {
  final String examTitle;
  final List<RequestRubric> requests;

  const Rubric({required this.examTitle, required this.requests});

  double get totalPoints => requests.fold(0.0, (sum, r) => sum + r.maxPoints);

  factory Rubric.fromJson(Map<String, dynamic> j) => Rubric(
    examTitle: j['examTitle'] as String,
    requests: (j['requests'] as List)
        .map((r) => RequestRubric.fromJson(r as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'examTitle': examTitle,
    'requests': requests.map((r) => r.toJson()).toList(),
  };
}
