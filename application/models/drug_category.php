<?php
class Drug_Category extends Doctrine_Record {
	public function setTableDefinition() {
		$this -> hasColumn('Category_Name', 'text');
	}

	public function setUp() {
		$this -> setTableName('drug_category');
		$this -> hasMany('Drug as Category_Drugs', array('local' => 'id', 'foreign' => 'Drug_Category'));
	}

	public static function getAll() {
		$query = Doctrine_Query::create() -> select("*") -> from("Drug_Category");
		$categories = $query -> execute();
		return $categories;
	}

}
