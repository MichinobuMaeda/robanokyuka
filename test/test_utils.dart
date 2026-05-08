import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/service.dart';

List<Gengo> gengos() => [
  Gengo(date: Cal(1868, 1, 25), name: '明治', short: 'M'),
  Gengo(date: Cal(1912, 7, 30), name: '大正', short: 'T'),
  Gengo(date: Cal(1926, 12, 25), name: '昭和', short: 'S'),
  Gengo(date: Cal(1989, 1, 8), name: '平成', short: 'H'),
  Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R'),
];
