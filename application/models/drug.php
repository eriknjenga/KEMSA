<?php
class Drug extends Doctrine_Record {
	public function setTableDefinition() {
		$this -> hasColumn('Kemsa_Code', 'varchar',20);
		$this -> hasColumn('Drug_Name', 'text');
		$this -> hasColumn('Unit_Size', 'varchar',100);
		$this -> hasColumn('Unit_Cost', 'varchar',20);
		$this -> hasColumn('Drug_Category', 'varchar',10); 
	}

	public function setUp() {
		$this -> setTableName('drug');
		$this -> hasOne('Drug_Category as Category', array('local' => 'Drug_Category', 'foreign' => 'id'));
	}

	public static function getAll() {
		$query = Doctrine_Query::create() -> select("*") -> from("Drug");
		$drugs = $query -> execute();
		return $drugs;
	}

}
