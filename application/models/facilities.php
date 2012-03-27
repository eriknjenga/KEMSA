<?php
class Facilities extends Doctrine_Record {
	public function setTableDefinition() {
		$this -> hasColumn('facility_code', 'varchar',30);
		$this -> hasColumn('facility_name', 'varchar',30);
		$this -> hasColumn('district', 'varchar',30);
	}

	public function setUp() {
		$this -> setTableName('facilities');
	}

	public static function getAll() {
		$query = Doctrine_Query::create() -> select("*") -> from("districts");
		$drugs = $query -> execute();
		return $drugs;
	}
	public function getFacilities($district){
		$query = Doctrine_Query::create() -> select("*") -> from("facilities")->where("district='$district'")->OrderBy("facility_name asc");
		$drugs = $query -> execute();
		return $drugs;
	}
}
