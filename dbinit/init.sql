-- Usa o banco de dados
use fabrica_db;

-- Cria as tabelas
create table fabrica_db.tb_tipo_sensor(tipo_sensor_id int, tipo_sensor varchar(30));

create table fabrica_db.tb_localidade(localidade_id int, cliente varchar(100), departmento varchar(100), nome_edificio varchar(100), sala varchar(100), andar varchar(100), localidade_andar varchar(100), latitude double, longitude double);

create table fabrica_db.tb_sensores(sensor_id int primary key, tipo_sensor_id int, localidade_id int);

-- Insere registros para os metadados
insert into tb_tipo_sensor values(1, 'Temperatura');
insert into tb_tipo_sensor values(2, 'Humidade');

insert into tb_localidade values(1, 'Fabrica', 'Operacoes', 'Rua 1', '100', 'Andar 1', 'C-101', 40.710936, -74.008500);
insert into tb_localidade values(2, 'Fabrica', 'Operacoes', 'Rua 2', '201', 'Andar 2', 'O-201', 40.712515, -74.015386);
insert into tb_localidade values(3, 'Fabrica', 'Operacoes', 'Rua 1', '101', 'Andar 1', 'O-382', 40.736370, -74.028755);
insert into tb_localidade values(4, 'Fabrica', 'Operacoes', 'Rua 2', '202', 'Andar 2', 'O-293', 40.715856, -74.033391);

insert into tb_sensores values(1, 1, 1);
insert into tb_sensores values(2, 1, 2);
insert into tb_sensores values(3, 1, 3);
insert into tb_sensores values(4, 1, 4);
insert into tb_sensores values(5, 2, 1);
insert into tb_sensores values(6, 2, 2);
insert into tb_sensores values(7, 2, 3);
insert into tb_sensores values(8, 2, 4);