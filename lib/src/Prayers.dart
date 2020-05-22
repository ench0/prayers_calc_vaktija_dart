import 'dart:math';
import 'package:prayers_calc/src/func.dart';

class Prayers {
  DateTime dawn;
  DateTime sunrise;
  DateTime midday;
  DateTime afternoon;
  DateTime sunset;
  DateTime dusk;
  DateTime dawnTomorrow;
  DateTime duskYesterday;
  DateTime midnight;
  DateTime lastThird;

  Prayers(
    double lat,
    double long,
    double altitude,
    double angle,
    int timezone, {
    int year,
    int month,
    int day,
    int asrMethod,
    double ishaAngle,
    bool summerTimeCalc: true,
  }) {
    DateTime timestamp = DateTime.now().toUtc();
    DateTime beginingOfYear = DateTime.utc(timestamp.year); // Jan 1, 0:00

    // define date in utc
    DateTime date = DateTime.utc(year ?? timestamp.year,
        month ?? timestamp.month, day ?? timestamp.day, 0, 0);
    // local date needed for dst calc
    DateTime dateLocal = DateTime(year ?? timestamp.year,
        month ?? timestamp.month, day ?? timestamp.day, 12, 0);
    int adjustDST = summerTimeCalc && isDSTCalc(dateLocal) ? 1 : 0;

    // adjust times
    Duration adjustTime = Duration(hours: adjustDST);

    double H = altitude; // height above sea level in meters
    double B = lat; //	Latitude (Degrees)
    double L = long; // Longitude (Degrees)
    int Sh = asrMethod ?? 1; //	Sh=1 (Shafii) - Sh=2 (Hanafi)

    int TZ = timezone;

    // int J = 142; //	Day of Year
    // int hoursSinceBeginingOfYear = date.difference(beginingOfYear).inHours;
    // int J =
    // (hoursSinceBeginingOfYear / 24).floor(); // because Jan 1 should be 0

    // date needs to be utc for accurate calculation
    int J = date.difference(beginingOfYear).inDays;

    print(date);
    // print(hoursSinceBeginingOfYear / 24);
    print(date.difference(beginingOfYear).inDays);

    double Gd = angle; //	Dawn’s Twilight Angle (15°-19°)
    double Gn = ishaAngle ?? angle; // Night’s Twilight Angle (15°-19°)
    int R = 15 * TZ; // Reference Longitude (Degrees)

    print(Gd);
    print(Gn);
    // ***** Solar Declination D (Degrees)
    double gama = 2 * pi * (J - 0) / 365; // or J-1? //TODO: 366 for leap
    double Drad = 0.006918 -
        0.399912 * cos(gama) +
        0.070257 * sin(gama) -
        0.006758 * cos(2 * gama) +
        0.000907 * sin(2 * gama) -
        0.002697 * cos(3 * gama) +
        0.00148 * sin(3 * gama);
    double D = Drad * 180 / pi;

// ***** Equation of Time EQT
    double T = 229.183 * // 1440/pi - to change from radians to minutes
        (0.000075 +
            0.001868 * cos(gama) -
            0.032077 * sin(gama) -
            0.014615 * cos(2 * gama) -
            0.040849 * sin(2 * gama)); //Equation of Time (Minutes)

// ***** Midday Z
    double Z = 12 + (R - L) / 15 - T / 60;

// ***** Offsets U Vd Vn W
// factors
    double factor = 12 / pi; // 180 / (15 * pi)
    double deg = pi / 180; // convert radians to degrees
    double sinCalc = sin(D * deg) * sin(B * deg);
    double cosCalc = cos(D * deg) * cos(B * deg);
// func
    double mainCalc(offset) => factor * acos((offset - sinCalc) / cosCalc);
    acot(x) => atan(1 / x);

// sunrise offset
    double U1 =
        sin((-0.83333 - 0.0347 * H / H.abs() * pow(H.abs(), 0.5)) * deg);
    double U = mainCalc(U1);

// dawn offset
    double Vd1 = -sin(Gd * deg);
    double Vd = mainCalc(Vd1);

// dusk offset
    double Vn1 = -sin(Gn * deg);
    double Vn = mainCalc(Vn1);

// afternoon offset
    double W1 = sin(acot(Sh + tan((B - D).abs() * deg)));
    double W = mainCalc(W1);

// ***** prayer times
    DateTime getTime(hourFraction) {
      int hour;
      if (hourFraction != double.nan)
        hour = hourFraction.floor();
      else
        hour = 23;

      int minute = ((hourFraction - hour) * 60).round();
      return DateTime.utc(date.year, date.month, date.day, hour, minute)
          .add(adjustTime);
    }

    print('$Z $Vd $U $W, $Vn');
    double dawnFraction = Z - Vd;
    this.dawn = getTime(dawnFraction);
    double sunriseFraction = Z - U;
    this.sunrise = getTime(sunriseFraction);

    double middayFraction = Z;
    this.midday = getTime(middayFraction);

    double afternoonFraction = Z + W;
    this.afternoon = getTime(afternoonFraction);

    double sunsetFraction = Z + U;
    this.sunset = getTime(sunsetFraction);

    print('****');
    double duskFraction = Vn.isNaN ? 0 : Z + Vn;
    print('****${Vn.isNaN}');

    this.dusk = getTime(duskFraction);

    // ***** Sunnah times

    // SunnahTimes sunnahTimes = SunnahTimes(
    //   B,
    //   L,
    //   H,
    //   Gd,
    //   TZ,
    //   date: date,
    //   asrMethod: Sh,
    //   ishaAngle: Gn,
    // );
  }
}
