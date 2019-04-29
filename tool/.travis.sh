#!/usr/bin/env bash
export POSTGRES_USERNAME="angel_orm"
export POSTGRES_PASSWORD="angel_orm" 
set -ex

function angel_orm_test () {
    cd $1;
    pub get;
    pub run test;
    cd ..
}

cd angel_orm_generator;
pub get;
echo 1 | pub run build_runner build --delete-conflicting-outputs;
cd ..;
angel_orm_test angel_orm_postgres
angel_orm_test angel_orm_service
