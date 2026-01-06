-- Iceberg접속을 위해 metastore DB를 미리 만들어 둬야 함.(자동 생성 안됨)
-- ※ Spark, Hive metastore 의존성 없고, trino에서 sql로 자유롭게 수정 가능
--- [설치방법]
--   1) sql문으로 metastore 생성
---  2) iceberg.properties.template 복사
---  3) rules.json 에 iceberg접근 권한 추가
---  4) minio에 iceberg.db 버킷 생성
---  5) trino 재기동하면 iceberg라는 catalog가 보임.
---  6) create schema duchboy 생성해서 사용.

CREATE DATABASE iceberg_db WITH OWNER metauser;

CREATE TABLE IF NOT EXISTS iceberg_tables(
  catalog_name            VARCHAR(255) NOT NULL,
  table_namespace         VARCHAR(255) NOT NULL,
  table_name              VARCHAR(255) NOT NULL,
  metadata_location       VARCHAR(1000),
  previous_metadata_location VARCHAR(1000),
  PRIMARY KEY(catalog_name, table_namespace, table_name)
);

CREATE TABLE IF NOT EXISTS iceberg_namespace_properties(
  catalog_name  VARCHAR(255) NOT NULL,
  namespace     VARCHAR(255) NOT NULL,
  property_key  VARCHAR(255),
  property_value VARCHAR(1000),
  PRIMARY KEY(catalog_name, namespace, property_key)
);

ALTER TABLE iceberg_tables               OWNER TO metauser;
ALTER TABLE iceberg_namespace_properties OWNER TO metauser;
