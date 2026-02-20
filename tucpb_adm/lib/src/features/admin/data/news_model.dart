import 'package:cloud_firestore/cloud_firestore.dart';

enum VisibilidadeNoticia { todos, perfis, nenhum }

enum CategoriaNoticia {
  informacoes,
  dicas,
  curiosidades,
  institucional,
  espiritual,
}

extension CategoriaNoticiaExt on CategoriaNoticia {
  String get label {
    switch (this) {
      case CategoriaNoticia.informacoes: return 'Informações';
      case CategoriaNoticia.dicas:       return 'Dicas';
      case CategoriaNoticia.curiosidades: return 'Curiosidades';
      case CategoriaNoticia.institucional: return 'Institucional';
      case CategoriaNoticia.espiritual:    return 'Espiritual';
    }
  }

  static CategoriaNoticia fromString(String val) {
    return CategoriaNoticia.values.firstWhere(
      (e) => e.label == val,
      orElse: () => CategoriaNoticia.informacoes,
    );
  }
}

class Noticia {
  final String id;
  final String titulo;
  final String assunto;
  final String conteudo;
  final CategoriaNoticia categoria;
  final String? imagemUrl;
  final String? videoUrl;
  final String? pdfUrl;
  final VisibilidadeNoticia visibilidade;
  final List<String> perfisPermitidos;
  final bool isDestaque;
  final bool isPublicada;
  final bool isArquivada;
  final DateTime dataCriacao;
  final String autorId;
  final String autorNome;

  Noticia({
    required this.id,
    required this.titulo,
    required this.assunto,
    required this.conteudo,
    required this.categoria,
    this.imagemUrl,
    this.videoUrl,
    this.pdfUrl,
    required this.visibilidade,
    required this.perfisPermitidos,
    this.isDestaque = false,
    this.isPublicada = true,
    this.isArquivada = false,
    required this.dataCriacao,
    required this.autorId,
    required this.autorNome,
  });

  factory Noticia.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Noticia(
      id: doc.id,
      titulo: d['titulo'] ?? '',
      assunto: d['assunto'] ?? '',
      conteudo: d['conteudo'] ?? '',
      categoria: CategoriaNoticiaExt.fromString(d['categoria'] ?? ''),
      imagemUrl: d['imagemUrl'],
      videoUrl: d['videoUrl'],
      pdfUrl: d['pdfUrl'],
      visibilidade: VisibilidadeNoticia.values.firstWhere(
        (e) => e.name == (d['visibilidade'] ?? 'todos'),
        orElse: () => VisibilidadeNoticia.todos,
      ),
      perfisPermitidos: List<String>.from(d['perfisPermitidos'] ?? []),
      isDestaque: d['isDestaque'] ?? false,
      isPublicada: d['isPublicada'] ?? true,
      isArquivada: d['isArquivada'] ?? false,
      dataCriacao: (d['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      autorId: d['autorId'] ?? '',
      autorNome: d['autorNome'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'assunto': assunto,
    'conteudo': conteudo,
    'categoria': categoria.label,
    if (imagemUrl != null) 'imagemUrl': imagemUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    if (pdfUrl != null) 'pdfUrl': pdfUrl,
    'visibilidade': visibilidade.name,
    'perfisPermitidos': perfisPermitidos,
    'isDestaque': isDestaque,
    'isPublicada': isPublicada,
    'isArquivada': isArquivada,
    'dataCriacao': Timestamp.fromDate(dataCriacao),
    'autorId': autorId,
    'autorNome': autorNome,
  };
}
