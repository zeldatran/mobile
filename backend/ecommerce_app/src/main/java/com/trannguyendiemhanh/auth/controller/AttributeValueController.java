package com.trannguyendiemhanh.auth.controller;

import com.trannguyendiemhanh.auth.entity.AttributeValue;
import com.trannguyendiemhanh.auth.service.AttributeValueService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/attribute-values")
public class AttributeValueController extends CrudController<AttributeValue, UUID> {
    public AttributeValueController(AttributeValueService service) {
        super(service);
    }
}
