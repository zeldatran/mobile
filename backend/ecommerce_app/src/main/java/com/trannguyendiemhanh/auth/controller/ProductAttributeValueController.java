package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.ProductAttributeValue;
import com.trannguyendiemhanh.auth.service.ProductAttributeValueService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/product-attribute-values")
public class ProductAttributeValueController extends CrudController<ProductAttributeValue, UUID> {
    public ProductAttributeValueController(ProductAttributeValueService service) {
        super(service);
    }
}
