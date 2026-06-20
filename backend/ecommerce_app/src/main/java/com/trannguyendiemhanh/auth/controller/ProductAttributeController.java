package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductAttribute;
import com.trannguyendiemhanh.auth.service.ProductAttributeService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-attributes")
public class ProductAttributeController extends CrudController<ProductAttribute, UUID> {
    public ProductAttributeController(ProductAttributeService service) {
        super(service);
    }
}
