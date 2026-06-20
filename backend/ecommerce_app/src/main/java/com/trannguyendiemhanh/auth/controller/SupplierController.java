package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.Supplier;
import com.trannguyendiemhanh.auth.service.SupplierService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/suppliers")
public class SupplierController extends CrudController<Supplier, UUID> {
    public SupplierController(SupplierService service) {
        super(service);
    }
}
