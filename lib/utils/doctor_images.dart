String imageUrlForSpecialty(String? specialty) {
  final normalized = _normalizeSpecialty(specialty);

  if (normalized.contains('cardio')) {
    return 'https://loremflickr.com/400/400/cardiology,doctor?lock=1';
  }
  if (normalized.contains('dermato')) {
    return 'https://loremflickr.com/400/400/dermatology,doctor?lock=2';
  }
  if (normalized.contains('general')) {
    return 'https://loremflickr.com/400/400/doctor,clinic?lock=3';
  }
  if (normalized.contains('pediatre')) {
    return 'https://loremflickr.com/400/400/pediatrician,doctor?lock=4';
  }
  if (normalized.contains('neuro')) {
    return 'https://loremflickr.com/400/400/neurology,doctor?lock=5';
  }
  if (normalized.contains('gyneco')) {
    return 'https://loremflickr.com/400/400/gynecology,doctor?lock=6';
  }
  if (normalized.contains('ortho')) {
    return 'https://loremflickr.com/400/400/orthopedic,doctor?lock=7';
  }
  if (normalized.contains('psychiatre')) {
    return 'https://loremflickr.com/400/400/psychiatrist,doctor?lock=8';
  }
  if (normalized.contains('psychologue')) {
    return 'https://loremflickr.com/400/400/psychology,therapy?lock=9';
  }
  if (normalized.contains('ophtalmo')) {
    return 'https://loremflickr.com/400/400/ophthalmology,doctor?lock=10';
  }
  if (normalized.contains('endocrino')) {
    return 'https://loremflickr.com/400/400/endocrinology,doctor?lock=11';
  }
  if (normalized.contains('gastro')) {
    return 'https://loremflickr.com/400/400/gastroenterology,doctor?lock=12';
  }
  if (normalized.contains('urolog')) {
    return 'https://loremflickr.com/400/400/urology,doctor?lock=13';
  }
  if (normalized == 'orl' || normalized.contains('otolary')) {
    return 'https://loremflickr.com/400/400/otolaryngology,doctor?lock=14';
  }
  if (normalized.contains('radio')) {
    return 'https://loremflickr.com/400/400/radiology,hospital?lock=15';
  }
  if (normalized.contains('nutrition')) {
    return 'https://loremflickr.com/400/400/nutritionist,health?lock=16';
  }
  if (normalized.contains('chirurg')) {
    return 'https://loremflickr.com/400/400/surgeon,operating-room?lock=17';
  }

  return 'https://loremflickr.com/400/400/doctor,clinic?lock=3';
}

String _normalizeSpecialty(String? input) {
  if (input == null) return '';
  return input
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('û', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ç', 'c')
      .replaceAll(' ', '');
}
