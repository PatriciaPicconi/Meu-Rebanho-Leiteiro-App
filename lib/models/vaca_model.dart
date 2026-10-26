class Vaca {
  final int? id;
  final String brinco;
  final String nome;
  final String dataNascimento;
  final String status;

  Vaca({
    this.id,
    required this.brinco,
    required this.nome,
    required this.dataNascimento,
    required this.status
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brinco': brinco,
      'nome': nome,
      'dataNascimento': dataNascimento,
      'status': status,
    };
  }

  factory Vaca.fromMap(Map<String, dynamic> map) {
    return Vaca(
      id: map['id'],
      brinco: map['brinco'],
      nome: map['nome'],
      dataNascimento: map['dataNascimento'],
      status: map['status'],
    );
  }
}