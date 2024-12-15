class LensModel {
  final String id;
  final String name;
  final String thumb;
  final String hotKey;

  LensModel( {required this.id, required this.name, required this.thumb, required this.hotKey,});
}

final List<LensModel> lenses = [
  LensModel(id: '1', name: 'Lense 1', thumb: 'assets/images/lens_1.jpg', hotKey: '+q'),
  LensModel(id: '2', name: 'Lense 2', thumb: 'assets/images/lens_2.jpg', hotKey: '+w'),
  LensModel(id: '3', name: 'Lense 3', thumb: 'assets/images/lens_3.jpg', hotKey: '+e'),
  LensModel(id: '4', name: 'Lense 4', thumb: 'assets/images/lens_4.jpg', hotKey: '+r'),
];