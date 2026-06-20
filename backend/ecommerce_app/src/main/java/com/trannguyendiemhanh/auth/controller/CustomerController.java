package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Customer;
import com.trannguyendiemhanh.auth.service.CustomerService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/customers")
public class CustomerController extends CrudController<Customer, UUID> {
    public CustomerController(CustomerService service) {
        super(service);
    }
}
