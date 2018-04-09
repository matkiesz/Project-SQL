--first queries from sql bootcamp
----------------------------------------------------------------------------------------------

/*Wy�wietl list� wniosk�w, kt�rych warto�� znacznie zmieni�a si� w trakcie ich procesowania*/

select id, kwota_rekompensaty_oryginalna - kwota_rekompensaty roznica
from wnioski
where  kwota_rekompensaty_oryginalna - kwota_rekompensaty != 0
--where kwota_rekompensaty <> kwota_rekompensaty_oryginalna -- inna wersja
order by 2 desc;
----------------------------------------------------------------------------------------------

*/ Wiedz�c, �e w firmie jedyne mo�liwe warto�ci rekompensaty na pasa�era to 250, 400 i 600, wylistuj pozosta�e, niespe�niaj�ce tego wymagania */
select *
from wnioski
where kwota_rekompensaty/liczba_pasazerow not in (250,400,600);

-- case sprawdzajacy kwoty 250/400/600
select id, kwota_rekompensaty, liczba_pasazerow, case when kwota_rekompensaty/liczba_pasazerow not in (250,400,600) then id end from wnioski;

-- jaki jest % wnioskow z blednymi kwotami?
select
  count(case when kwota_rekompensaty/liczba_pasazerow not in (250,400,600) then 1 end) liczba_blednych_wnioskow,
  count(1) liczba_wszystkich_wnioskow,
  count(case when kwota_rekompensaty/liczba_pasazerow not in (250,400,600) then 1 end)/count(1)::numeric procent_blednych
from wnioski;
----------------------------------------------------------------------------------------------

*/Jaka jest skala tego zjawiska?
  Jakiego % wniosk�w dotyczy ta sytuacja?
  Jaka jest minimalna r�nica?
  Jaka jest maksymalna r�nica?
  Jaka jest �rednia r�nica?
  Jaki jest rozk�ad r�nic w warto�ciach oryginalnych i finalnych?
 */

select
  count(case when kwota_rekompensaty - kwota_rekompensaty_oryginalna != 0 then id end) as liczba_roznych,
  count(1) wszystkie_wnioski,
  round(count(case when kwota_rekompensaty - kwota_rekompensaty_oryginalna != 0 then id end)/count(1)::numeric, 4) procent_roznicy
from wnioski;

-- min / max / srednia roznica
select count(case when kwota_rekompensaty - kwota_rekompensaty_oryginalna != 0 then id end) as liczba_roznych,
  min(kwota_rekompensaty_oryginalna - kwota_rekompensaty),
  max(kwota_rekompensaty_oryginalna - kwota_rekompensaty),
  avg(kwota_rekompensaty_oryginalna - kwota_rekompensaty)
from wnioski
where kwota_rekompensaty_oryginalna - kwota_rekompensaty != 0;

-- ROZK�ADY
-- a) po czasie
select to_char(data_utworzenia, 'YYYY-MM') data_utw,
  count(case when kwota_rekompensaty - kwota_rekompensaty_oryginalna != 0 then id end) as liczba_roznych,
  min(kwota_rekompensaty_oryginalna - kwota_rekompensaty),
  max(kwota_rekompensaty_oryginalna - kwota_rekompensaty),
  avg(kwota_rekompensaty_oryginalna - kwota_rekompensaty)
from wnioski
where kwota_rekompensaty_oryginalna - kwota_rekompensaty != 0
group by 1
order by 1;

-- b) po wysoko�ci rekompensaty
select
  case
    when kwota_rekompensaty_oryginalna - kwota_rekompensaty < 100 then '<100'
    when kwota_rekompensaty_oryginalna - kwota_rekompensaty < 250 then '<250'
    when kwota_rekompensaty_oryginalna - kwota_rekompensaty < 600 then '<600'
  ELSE '>600' end,
  count(case when kwota_rekompensaty - kwota_rekompensaty_oryginalna != 0 then id end) as liczba_roznych
from wnioski
where kwota_rekompensaty_oryginalna - kwota_rekompensaty != 0
group by 1
order by 1;

-- przyklad wykorzystania case z kwota rekompensaty
select id, kwota_rekompensaty,
  CASE
    when kwota_rekompensaty is null then 'brak'
    when kwota_rekompensaty <= 250 then 'ma�o wartosciowy'
    when kwota_rekompensaty <= 400 then '�redni'
    when kwota_rekompensaty <= 600 then 'wysoka warto��'
    else 'super'
  END,
  CASE
    when kwota_rekompensaty <= 600 then 'wysoka warto��'
    when kwota_rekompensaty <= 400 then '�redni'
    when kwota_rekompensaty <= 250 then 'ma�o wartosciowy'
    else 'super'
  END,
  CASE
    when kwota_rekompensaty >= 400 and kwota_rekompensaty < 600 then 'wysoka warto��'
    when kwota_rekompensaty >= 251 and kwota_rekompensaty < 400 then '�redni'
    when kwota_rekompensaty >= 0 and kwota_rekompensaty < 251 then 'ma�o wartosciowy'
    else 'super'
  END
from wnioski;
----------------------------------------------------------------------------------------------
/* Ile wniosk�w zosta�o ocenionych? Ile wniosk�w zosta�o zaakceptowanych?*/

select count(w.id) wszystkie, -- wszystkie wnioski jakie mamy
  count(a.id) ocenione, -- tylko ocenione wnioski wiec aliasem jest moja tabela analiza wnioskow
  count(a.id)/count(w.id)::numeric procent_ocenionych,
  count(case when a.status = 'zaakceptowany' then a.id end)/count(w.id)::numeric proc_zaakc, -- stosunek % zaakceptowanych do wszystkich
  count(case when a.status = 'zaakceptowany' then a.id end)/count(a.id)::numeric proc_zaakc_z_ocenionych -- stosunek % zaakceptowanych tylko do ocenionych! Roznica tylko w aliasie!
from wnioski w
left join analizy_wnioskow a ON w.id = a.id_wniosku; --left join dlatego ze licze konwersje


-- dane dla tabeli przestwnej po dacie utworzenia i dacie analizy
select to_char(w.data_utworzenia,'YYYY') data_utw, -- dla kazdego miesiaca utworzenia wniosku
  to_char(a.data_zakonczenia,'YYYY') data_zak, -- i dla kazdego miesiaca zaakceptowania wniosku
  count(w.id) liczba_wnioskow, -- podaje ile ich jest
  sum(count(w.id)) over(partition by to_char(w.data_utworzenia,'YYYY')) wnioskow_w_oknie, -- oraz mowie ile jest wnioskow wszystkich w calym oknie
  count(w.id) / sum(count(w.id)) over(partition by to_char(w.data_utworzenia,'YYYY')) procent -- ostatecznie wyliczam ich procent
from wnioski w
left join analizy_wnioskow a ON w.id = a.id_wniosku
group by 1,2;

----------------------------------------------------------------------------------------------

/* Zestawienie na kt�rym przedstawiam procentowy udzia� zaakceptowanych i odrzuconych wniosk�w w zale�no�ci od j�zyka */

select w.jezyk, a.status, count(1),
  round(count(1) / sum(count(1)) over(PARTITION BY jezyk)::numeric, 4) procent
from wnioski w
join analizy_wnioskow a ON w.id = a.id_wniosku
group by 1,2
order by 1,2;

-- inny przyklad z funkcja okna
select typ_wniosku, powod_operatora, count(1),
  sum(count(1)) over() wszystkie_wnioski,
  count(1) / sum(count(1)) over()::numeric procent_z_calej_grupy,
  sum(count(1)) over(partition by typ_wniosku),
  count(1) / sum(count(1)) over(partition by typ_wniosku) procent_z_typu_wniosku
from wnioski
group by 1,2
order by 1,2;

----------------------------------------------------------------------------------------------

/* Podaj mi liczb� wniosk�w w ka�dym miesi�cu, wraz z podsumowaniem ca�kowitej liczby wniosk�w na samym dole */

-- wersja 1
select to_char(data_utworzenia, 'YYYY-MM'), count(1) liczba_wnioskow -- czesc liczaca miesiac po miesiacu
from wnioski
group by 1
union -- scal wyniki
select 'podsumowanie', count(1) from wnioski -- jeden rekord, nie ma grupowania po miesiacach!
order by 1;

-- wersja 2: odwrotna kolejnosc, ale ten sam wynik
select 'podsumowanie', count(1) from wnioski
union
select to_char(data_utworzenia, 'YYYY-MM'), count(1) liczba_wnioskow
from wnioski
group by 1
order by 1;

-- wersja 3: z uzyciem with
with moje_dane as (
  select to_char(data_utworzenia, 'YYYY-MM'), count(1) liczba_wnioskow
  from wnioski
  group by 1
  order by 1
)

select * from moje_dane
union
select 'podsumowanie', sum(liczba_wnioskow) from moje_dane
----------------------------------------------------------------------------------------------

/*
  Aby zwi�kszy� przychody, przygotuj list� nowych wniosk�w, kt�re maj� inn podobny wniosek ju� wyp�acony. Struktura listy:
  - Id wniosku o statusie nowy
  - Identyfikator podr�y wniosku o statusie nowy
  - Id wniosku wyp�aconego
  - Status wniosku wyp�aconego
  - Identyfikator podr�y wniosku o statusie wyp�acony
 */

with moje_dane as ( -- wejsciowa lista wnioskow nowych i wyplaconych, ktore potem bedziemy sprawdzac
  select w.id, w.stan_wniosku, s2.identyfikator_podrozy, w.data_utworzenia
  from wnioski w
    join podroze p ON w.id = p.id_wniosku
    join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
  where stan_wniosku in ('nowy','wyplacony')
  and s2.identyfikator_podrozy not like '%--%'
  and s2.czy_zaklocony = true
  order by 1),
lista_podobnych as ( -- self join do tabeli wyzej
  select md_nowe.id id_nowego, md_nowe.stan_wniosku, md_nowe.identyfikator_podrozy, md_wyplacone.id, md_wyplacone.stan_wniosku, md_wyplacone.identyfikator_podrozy
  from moje_dane md_nowe
    join moje_dane md_wyplacone on md_wyplacone.identyfikator_podrozy = md_nowe.identyfikator_podrozy
  where md_nowe.stan_wniosku = 'nowy' -- wez wnioski o statusie nowe
  and md_wyplacone.stan_wniosku = 'wyplacony' -- i dodaj do nich podobne and tylko wyplacone
  --and md_wyplacone.id < md_nowe.id -- sposb 1 (tylko keidy pewnosc ze id narastaj�co w czasie)
  and md_wyplacone.data_utworzenia < md_nowe.data_utworzenia -- sposob 2 z uzyciem daty zamiast ID
  )
select *
from lista_podobnych
;

----------------------------------------------------------------------------------------------
/* Monitoring z miesi�ca na miesi�c widz�c procentow� zmian� w stosunku do poprzedniego miesi�ca. Przygotuj zestawienie pokazuj�ce takie zmiany
  Jako szef firmy chc� monitorowa� liczb� wniosk�w z roku na rok widz�c procentow� zmian� w stosunku do poprzedniego roku. Przygotuj zestawienie pokazuj�ce takie zmiany */
select
  --to_char(data_utworzenia,'YYYY'),  -- wersja roczna
  to_char(data_utworzenia,'YYYY-MM'),  -- wersja miesieczna
  count(1) aktualny_miesiac,
  lag(count(1)) over() poprzedni_miesiac,
  (count(1) - lag(count(1)) over()) / lag(count(1)) over()::numeric mom
from wnioski
group by 1
order by 1;


----------------------------------------------------------------------------------------------
/*  1. Z kt�rego kraju mamy najwi�cej wniosk�w? */

select kod_kraju, count(1) as liczbawnioskow
from wnioski
group by 1
order by 2 DESC;


/* 2. Z kt�rego j�zyka mamy najwi�cej wniosk�w? */

select jezyk, count(1) as liczbawnioskow
from wnioski
group by 1
ORDER BY 2 DESC;

/* 3. Ile % procent klient�w podr�owa�o w celach biznesowych a ilu w celach prywatnych? */

select typ_podrozy, count(1) as liczba,
count(1) / sum(count(1)) over() procent
from wnioski
    join klienci k ON wnioski.id = k.id_wniosku
GROUP BY 1;

/* 4. Jak procentowo rozk�adaj� si� �r�d�a polecenia? */

select zrodlo_polecenia, count(1) as liczba,
      round(count(1) / sum(count(1)) over()::numeric,4) procent
  from wnioski
    where wnioski.zrodlo_polecenia is not NULL
GROUP BY 1
order by 2 ASC;

/* 5. Ile podr�y to trasy z�o�one z jednego / dw�ch / trzech / wi�cej tras? */

with trasy as (
select id_wniosku as wniosek,
       case WHEN count(identyfikator_podrozy) = 1 then 1 else 0 end::numeric jednatrasa,
       case WHEN count(identyfikator_podrozy) = 2 then 1 else 0 end::numeric dwietrasy,
       case WHEN count(identyfikator_podrozy) = 3 then 1 else 0 end::numeric trzytrasy,
       case WHEN count(identyfikator_podrozy) > 3 then 1 else 0 end::numeric wiecej
from szczegoly_podrozy
join podroze p ON szczegoly_podrozy.id_podrozy = p.id
GROUP BY 1
order by 5 DESC )

select * from trasy
UNION
select count(wniosek),
sum(jednatrasa)/count(wniosek)::NUMERIC,
sum(dwietrasy)/count(wniosek)::NUMERIC,
sum(trzytrasy)/count(wniosek)::NUMERIC,
sum(wiecej)/count(wniosek)::NUMERIC from trasy;


/* 6. Na kt�re konto otrzymali�my najwi�cej / najmniej rekompensaty? */

select konto, count(kwota)
from szczegoly_rekompensat
GROUP BY 1
order by 2;

/* 7.  Kt�ry dzie� jest rekordowym w firmie w kwestii utworzonych wniosk�w? */

select to_char(data_utworzenia, 'YYYY-MM-DD') as datautworzenia, count(1)
from wnioski
GROUP BY 1
ORDER BY 2 DESC ;


/* 8. Kt�ry dzie� jest rekordowym w firmie w kwestii otrzymanych rekompensat?  */

select to_char(data_otrzymania, 'YYYY-MM-DD'), count(1)
from szczegoly_rekompensat
GROUP BY 1
ORDER BY 2 DESC ;

/* 9. Jaka jest dystrubucja tygodniowa wniosk�w wed�ug kana��w? (liczba wniosk�w w danym tygodniu w ka�dym kanale) */

select to_char(data_utworzenia, 'WW') as tydzien, kanal, count(1)
from wnioski
group by 1,2;

/* 10. Lista wniosk�w przeterminowanych (przeterminowany = utworzony w naszej firmie powy�ej 3 lat od daty podr�y)
 */

select w.id
from wnioski w
  join podroze p on w.id = p.id_wniosku
  join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
  where w.data_utworzenia::date - data_wyjazdu::date > 1095
group by 1;


/* 11. Jaka cz�� naszych klient�w to powracaj�ce osoby? */

SELECT email,
       count(1) as iloscwnioskow,
       case WHEN count(1) > 1 then 1 else 0 end::numeric powracajacy
FROM wnioski w
join klienci k ON w.id = k.id_wniosku
group by 1
  order by 2 DESC




/* 12. Jaka cz�� naszych wsp�pasa�er�w to osoby, kt�re ju� wcze�niej pojawi�y si� na jakim� wniosku? */

SELECT email,
         count(1) as iloscwnioskow,
       case WHEN count(1) > 1 then 1 end::numeric pojawiajacy
FROM wnioski w
join wspolpasazerowie w2 ON w.id = w2.id_wniosku
group by 1
order by 2 DESC;




/* 13. Jaka cz�� klient�w pojawi�a si� na innych wnioskach jako wsp�pasa�er? */

Select  k.email as mailaklientow,
         case WHEN k.email = wspolpasazerowie.email then 1 end::numeric bylwspolpasazerem
from wspolpasazerowie
join wnioski w2 ON wspolpasazerowie.id_wniosku = w2.id
join klienci k ON w2.id = k.id_wniosku
group by 1,2
order by 2 ASC;


/*  14. Jaki jest czas od z�o�enia pierwszego do kolejnego wniosku dla klient�w kt�rzy maj� min 2 wnioski? */

select email as klient, w2.data_utworzenia as datautworzenia, count(w2.data_utworzenia) over (PARTITION BY email),
  lead(min(w2.data_utworzenia)) over()::date -  min(w2.data_utworzenia)::date as czas_od_1_do_2
  from klienci k
    join wnioski w2 ON k.id_wniosku = w2.id
GROUP BY 1, 2
order by 3 DESC ;