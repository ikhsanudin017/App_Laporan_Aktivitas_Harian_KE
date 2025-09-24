import 'dart:convert';

import '../models/form_models.dart';

const String _rawFormConfigs = r'''
{
  "USTADZ_YULI": {
    "role": "USTADZ_YULI",
    "title": "Form Laporan Harian - Ustadz Yuli",
    "fields": [
      {
        "name": "aktivitasHarian",
        "label": "Aktivitas Harian",
        "type": "textarea",
        "required": true,
        "placeholder": "Masukkan aktivitas harian Anda..."
      }
    ]
  },
  "BAPAK_TOHA": {
    "role": "BAPAK_TOHA",
    "title": "Form Laporan Harian - Bapak Toha",
    "fields": [
      {
        "name": "aktivitasHarian",
        "label": "Aktivitas Harian",
        "type": "textarea",
        "required": true,
        "placeholder": "Masukkan aktivitas harian Anda..."
      }
    ]
  },
  "BAPAK_SAYUDI": {
    "role": "BAPAK_SAYUDI",
    "title": "Form Laporan Harian - Bapak Sayudi",
    "fields": [
      {
        "name": "angsuran",
        "label": "Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "fundingB2B",
        "label": "Funding B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "fundingPersonal",
        "label": "Funding Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "survey",
        "label": "Survey",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "kegiatan",
        "label": "Aktivitas Lainnya (*Selain yang ada pada tabel)",
        "type": "textarea",
        "required": false,
        "placeholder": "Masukkan aktivitas lainnya..."
      }
    ]
  },
  "BPK_WINARNO": {
    "role": "BPK_WINARNO",
    "title": "Form Laporan Harian - Bpk Winarno",
    "fields": [
      {
        "name": "angsuran",
        "label": "Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "survey",
        "label": "Survey",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "kegiatan",
        "label": "Aktivitas Lainnya (*Selain yang ada pada tabel)",
        "type": "textarea",
        "required": false,
        "placeholder": "Masukkan aktivitas lainnya..."
      }
    ]
  },
  "BAPAK_ARWAN": {
    "role": "BAPAK_ARWAN",
    "title": "Form Laporan Harian - Bapak Arwan",
    "fields": [
      {
        "name": "angsuran",
        "label": "Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "fundingB2B",
        "label": "Funding B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "fundingPersonal",
        "label": "Funding Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "marketingB2B",
        "label": "Marketing B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Marketing"
      },
      {
        "name": "marketingPersonal",
        "label": "Marketing Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Marketing"
      },
      {
        "name": "survey",
        "label": "Survey",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "kegiatan",
        "label": "Aktivitas Lainnya (*Selain yang ada pada tabel)",
        "type": "textarea",
        "required": false,
        "placeholder": "Masukkan aktivitas lainnya..."
      }
    ]
  },
  "BAPAK_DIAH": {
    "role": "BAPAK_DIAH",
    "title": "Form Laporan Harian - Bapak Diah Supriyanto",
    "fields": [
      {
        "name": "angsuran",
        "label": "Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "fundingB2B",
        "label": "Funding B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "fundingPersonal",
        "label": "Funding Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Funding"
      },
      {
        "name": "marketingB2B",
        "label": "Marketing B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Marketing"
      },
      {
        "name": "marketingPersonal",
        "label": "Marketing Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0",
        "category": "Marketing"
      },
      {
        "name": "survey",
        "label": "Survey",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "kegiatan",
        "label": "Aktivitas Lainnya (*Selain yang ada pada tabel)",
        "type": "textarea",
        "required": false,
        "placeholder": "Masukkan aktivitas lainnya..."
      }
    ]
  },
  "BAPAK_PRASETYO": {
    "role": "BAPAK_PRASETYO",
    "title": "Form Laporan Harian - Bapak Prasetyo Dani",
    "fields": [
      {
        "name": "ktp",
        "label": "KTP",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "adr",
        "label": "ADR",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "quran",
        "label": "QUR'AN",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "wakaf",
        "label": "WAKAF",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "gota",
        "label": "GOTA",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "b2b",
        "label": "B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "maintenance",
        "label": "Maintenance",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "lainLain",
        "label": "Aktivitas Lainnya",
        "type": "textarea",
        "required": false,
        "placeholder": "Aktivitas lainnya..."
      }
    ]
  },
  "BAPAK_GIYARTO": {
    "role": "BAPAK_GIYARTO",
    "title": "Form Laporan Harian - Bapak Giyarto",
    "fields": [
      {
        "name": "ktp",
        "label": "KTP",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "adr",
        "label": "ADR",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "quran",
        "label": "QUR'AN",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "wakaf",
        "label": "WAKAF",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "gota",
        "label": "GOTA",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "b2b",
        "label": "B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "maintenance",
        "label": "Maintenance",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan tambahan..."
      },
      {
        "name": "lainLain",
        "label": "Aktivitas Lainnya",
        "type": "textarea",
        "required": false,
        "placeholder": "Aktivitas lainnya..."
      }
    ]
  },
  "ADMIN": {
    "role": "ADMIN",
    "title": "Form Laporan Harian - Administrator",
    "fields": [
      {
        "name": "aktivitasHarian",
        "label": "Aktivitas Harian",
        "type": "textarea",
        "required": false,
        "placeholder": "Aktivitas harian..."
      },
      {
        "name": "angsuran",
        "label": "Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "kegiatan",
        "label": "Kegiatan",
        "type": "textarea",
        "required": false,
        "placeholder": "Kegiatan..."
      },
      {
        "name": "fundingB2B",
        "label": "Funding B2B",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "fundingPersonal",
        "label": "Funding Personal",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "survey",
        "label": "Survey",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "keterangan",
        "label": "Keterangan",
        "type": "textarea",
        "required": false,
        "placeholder": "Keterangan..."
      },
      {
        "name": "marketingFunding",
        "label": "Marketing Funding",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "pembayaranAngsuran",
        "label": "Pembayaran Angsuran",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "visitingAnggota",
        "label": "Visiting Anggota",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "pencairanKredit",
        "label": "Pencairan Kredit",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "supervising",
        "label": "Supervising",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "evaluasi",
        "label": "Evaluasi",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "meeting",
        "label": "Meeting",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "visitingCabang",
        "label": "Visiting Cabang",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "maintenance",
        "label": "Maintenance",
        "type": "dropdown-number",
        "required": false,
        "placeholder": "0"
      },
      {
        "name": "lainLain",
        "label": "Lain-Lain",
        "type": "textarea",
        "required": false,
        "placeholder": "Aktivitas lain-lain..."
      }
    ]
  }
}
''';

final Map<String, FormConfig> formConfigs =
    (jsonDecode(_rawFormConfigs) as Map<String, dynamic>).map((key, value) =>
        MapEntry(
            key, FormConfig.fromJson(Map<String, dynamic>.from(value as Map))));

FormConfig? resolveFormConfig(String role) {
  if (role.isEmpty) return null;
  return formConfigs[role] ??
      formConfigs[role.toUpperCase()] ??
      formConfigs['ADMIN'];
}
