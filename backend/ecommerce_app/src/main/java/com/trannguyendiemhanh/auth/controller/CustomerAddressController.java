package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.CustomerAddress;
import com.trannguyendiemhanh.auth.service.CustomerAddressService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/customer-addresses")
public class CustomerAddressController extends CrudController<CustomerAddress, UUID> {
    public CustomerAddressController(CustomerAddressService service) {
        super(service);
    }
}
