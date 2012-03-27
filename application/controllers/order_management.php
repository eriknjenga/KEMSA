<?php
class Order_Management extends MY_Controller {

	function __construct() {
		parent::__construct();
	}

	public function index() {
		$this -> listing();
	}

	public function new_order() {
		$data['title'] = "New Order";
		$data['content_view'] = "new_order_v";
		$data['banner_text'] = "New Order";
		$data['link'] = "order_management";
		$data['drug_categories'] = Drug_Category::getAll();
		$data['quick_link'] = "new_order";
		$this -> load -> view("template", $data);
	}

	public function all_deliveries() {
		$data['title'] = "All Deliveries";
		$data['content_view'] = "dispatched_listing_v";
		$data['banner_text'] = "Dispatched Orders";
		$data['link'] = "order_management";
		$data['quick_link'] = "all_deliveries";
		$this -> load -> view("template", $data);
	}

	public function update_delivery_status() {
		$data['title'] = "Update Delivery Status";
		$data['content_view'] = "update_delivery_status_v";
		$data['banner_text'] = "Update Status";
		$data['link'] = "order_management";
		$data['quick_link'] = "all_deliveries";
		$this -> load -> view("template", $data);
	}

	public function listing() {
		$data['title'] = "All Orders";
		$data['content_view'] = "orders_listing_v";
		$data['banner_text'] = "All Orders";
		$data['link'] = "order_management"; 
		$this -> load -> view("template", $data);
	}
	public function drug_issue(){
		$data['title'] = "New Drug Issue";
		$data['content_view'] = "new_issue_v";
		$data['banner_text'] = "New Drug Issue";
		$data['link'] = "order_management";
		$data['drug_categories'] = Drug_Category::getAll();
		$data['quick_link'] = "drug_issue";
		$this -> load -> view("template", $data);
	}
	public function stock_level(){
		$data['title'] = "Stock";
		$data['content_view'] = "stock_level_v";
		$data['banner_text'] = "Stock Level";
		$data['link'] = "order_management";
		$data['counties'] = Counties::getAll();
		$data['drug_categories'] = Drug_Category::getAll();
		$data['quick_link'] = "stock_level";
		$this -> load -> view("template", $data);
	}
	public function getDistrict(){
		//for ajax
		$county=$_POST['county'];
		$districts=Districts::getDistrict($county);
		$list="";
		foreach ($districts as $districts) {
			$list.=$districts->id;
			$list.="*";
			$list.=$districts->district;
			$list.="_";
		}
		echo $list;
	}
	public function getFacilities(){
		//for ajax
		$district=$_POST['district'];
		$facilities=Facilities::getFacilities($district);
		$list="";
		foreach ($facilities as $facilities) {
			$list.=$facilities->id;
			$list.="*";
			$list.=$facilities->facility_name;
			$list.="_";
		}
		echo $list;
	}
}
