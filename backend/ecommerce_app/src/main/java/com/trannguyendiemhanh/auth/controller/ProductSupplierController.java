package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductSupplier;
import com.trannguyendiemhanh.auth.service.ProductSupplierService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-suppliers")
public class ProductSupplierController extends CrudController<ProductSupplier, UUID> {
    public ProductSupplierController(ProductSupplierService service) {
        super(service);
    }
}
