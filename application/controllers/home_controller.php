<?php
if (!defined('BASEPATH'))
	exit('No direct script access allowed');

class Home_Controller extends MY_Controller {
	function __construct() {
		parent::__construct();
	}

	public function index() {

		$this -> home();
	}

	public function home() {
		//
		/*$rights = User_Right::getRights($this -> session -> userdata('access_level'));
		$menu_data = array();
		$menus = array();
		$counter = 0;
		foreach ($rights as $right) {
			$menu_data['menus'][$right -> Menu] = $right -> Access_Type;
			$menus['menu_items'][$counter]['url'] = $right -> Menu_Item -> Menu_Url;
			$menus['menu_items'][$counter]['text'] = $right -> Menu_Item -> Menu_Text;
			$counter++;
		}
		$this -> session -> set_userdata($menu_data);
		$this -> session -> set_userdata($menus);*/
		$data['title'] = "System Home";
		$access_level = $this -> session -> userdata('user_indicator');
		
		if($access_level == "facility"){
			$data['content_view'] = "facility_home_v";
			$data['scripts'] = array("FusionCharts/FusionCharts.js"); 
		}
		else if($access_level == "moh"){
			$data['content_view'] = "moh_home_v";
			$data['scripts'] = array("FusionCharts/FusionCharts.js"); 
		}
		
		$data['banner_text'] = "System Home";
		$data['link'] = "home";
		$this -> load -> view("template", $data);

	}
 

}
