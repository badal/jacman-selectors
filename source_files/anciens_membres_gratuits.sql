-- Trouver les adhérents 2014, dont l'adhésion 2013 était gratuite

SELECT
  ad1.adhesion_locale_client_sage from adhesion_locale AS ad1
    LEFT JOIN adhesion_locale AS ad2
  ON ad1.adhesion_locale_client_sage=ad2.adhesion_locale_client_sage
  WHERE ad1.adhesion_locale_annee=2013
    AND ad2.adhesion_locale_annee=2014
    AND ad1.adhesion_locale_type='GT';
