import 'package:flutter_test/flutter_test.dart';
import 'package:kazwall/models/picture.dart';
import 'package:kazwall/services/search.dart';

Picture picture(String id, String type, List<String> tags, {int createdAt = 0}) =>
    Picture(id: id, type: type, file: '$id.jpg', thumb: '$id.jpg', tags: tags, createdAt: createdAt);

void main() {
  final pictures = [
    picture('lake', 'nature', ['Озеро', 'Кольсай'], createdAt: 1),
    picture('mosque', 'relig', ['Мечеть', 'Астана'], createdAt: 2),
    picture('yurt', 'culture', ['Юрта'], createdAt: 3),
  ];
  List<String> ids(String query) => Search.filter(pictures, query).map((p) => p.id).toList();

  test('точное совпадение по тегу идёт первым', () {
    expect(ids('озеро').first, 'lake');
  });

  test('если совпало только одно слово из двух, картинка всё равно находится', () {
    expect(ids('озеро байконур'), ['lake']);
  });

  test('опечатка находит самое похожее', () {
    expect(ids('кальсай').first, 'lake');
  });

  test('запрос, ни на что не похожий, показывает новые картинки', () {
    expect(ids('qwxz'), ['yurt', 'mosque', 'lake']);
  });

  test('одна буква — тоже запрос', () {
    expect(ids('ю'), isNotEmpty);
  });

  test('пустой запрос ничего не ищет', () {
    expect(ids('  '), isEmpty);
  });
}
